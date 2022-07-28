"""Functions for processing compiler and linker options."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load("@bazel_skylib//lib:collections.bzl", "collections")
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":collections.bzl", "set_if_true", "uniq")

# C and C++ compiler flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_CC_SKIP_OPTS = {
    "-fcolor-diagnostics": 1,
    "-isysroot": 2,
    "-mios-simulator-version-min": 1,
    "-miphoneos-version-min": 1,
    "-mmacosx-version-min": 1,
    "-mtvos-simulator-version-min": 1,
    "-mtvos-version-min": 1,
    "-mwatchos-simulator-version-min": 1,
    "-mwatchos-version-min": 1,
    "-target": 2,
}

# Swift compiler flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_SWIFTC_SKIP_OPTS = {
    # TODO: Make sure we should skip _all_ of these
    "-Xcc": 2,
    # TODO: Make sure we should skip _all_ of these
    "-Xfrontend": 2,
    "-Xwrapped-swift": 1,
    "-debug-prefix-map": 2,
    "-emit-module-path": 2,
    "-emit-object": 1,
    "-enable-batch-mode": 1,
    # TODO: See if we need to support this
    "-gline-tables-only": 1,
    "-module-name": 2,
    "-num-threads": 2,
    "-output-file-map": 2,
    "-parse-as-library": 1,
    "-sdk": 2,
    "-target": 2,
}

# Maps Swift compliation mode compiler flags to the corresponding Xcode values
_SWIFT_COMPILATION_MODE_OPTS = {
    "-incremental": "singlefile",
    "-no-whole-module-optimization": "singlefile",
    "-whole-module-optimization": "wholemodule",
    "-wmo": "wholemodule",
}

# Defensive list of features that can appear in the CC toolchain, but that we
# definitely don't want to enable (meaning we don't want them to contribute
# command line flags).
_UNSUPPORTED_CC_FEATURES = [
    "debug_prefix_map_pwd_is_dot",
    # TODO: See if we need to exclude or handle it properly
    "thin_lto",
    "module_maps",
    "use_header_modules",
    "fdo_instrument",
    "fdo_optimize",
]

# Compiler option processing

def _get_unprocessed_compiler_opts(*, ctx, target):
    """Returns the unprocessed compiler options for the given target.

    Args:
        ctx: The aspect context.
        target: The `Target` that the compiler options will be retrieved from.

    Returns:
        A `tuple` containing three elements:

        *   A `list` of C compiler options.
        *   A `list` of C++ compiler options.
        *   A `list` of all Swift compiler options.
        *   A `list` of user Swift compiler options.
    """

    # TODO: Handle perfileopts somehow?

    conlyopts = []
    cxxopts = []
    raw_swiftcopts = []
    user_swiftcopts = []

    for action in target.actions:
        if action.mnemonic == "SwiftCompile":
            # First two arguments are "worker" and "swiftc"
            raw_swiftcopts = action.argv[2:]

    if SwiftInfo in target or raw_swiftcopts:
        # Rule level swiftcopts are included in action.argv above
        user_swiftcopts = getattr(ctx.rule.attr, "copts", [])
        user_swiftcopts = _expand_locations(
            ctx = ctx,
            values = user_swiftcopts,
            targets = getattr(ctx.rule.attr, "swiftc_inputs", []),
        )
        user_swiftcopts = _expand_make_variables(
            ctx = ctx,
            values = user_swiftcopts,
            attribute_name = "copts",
        )
    elif CcInfo in target:
        cc_toolchain = find_cpp_toolchain(ctx)

        feature_configuration = cc_common.configure_features(
            ctx = ctx,
            cc_toolchain = cc_toolchain,
            requested_features = (
                # `CcCommon.ALL_COMPILE_ACTIONS` doesn't include objc...
                ctx.features + ["objc-compile", "objc++-compile"]
            ),
            unsupported_features = (
                ctx.disabled_features + _UNSUPPORTED_CC_FEATURES
            ),
        )
        variables = cc_common.create_compile_variables(
            feature_configuration = feature_configuration,
            cc_toolchain = cc_toolchain,
            user_compile_flags = [],
        )

        is_objc = apple_common.Objc in target
        base_copts = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = "objc-compile" if is_objc else "c-compile",
            variables = variables,
        )
        base_cxxopts = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = "objc++-compile" if is_objc else "c++-compile",
            variables = variables,
        )

        user_copts = getattr(ctx.rule.attr, "copts", [])
        user_copts = _expand_locations(
            ctx = ctx,
            values = user_copts,
            targets = getattr(ctx.rule.attr, "data", []),
        )
        user_copts = _expand_make_variables(
            ctx = ctx,
            values = user_copts,
            attribute_name = "copts",
        )

        if is_objc:
            objc = ctx.fragments.objc
            user_copts = (
                objc.copts +
                user_copts +
                objc.copts_for_current_compilation_mode
            )

        cpp = ctx.fragments.cpp
        conlyopts = base_copts + cpp.copts + cpp.conlyopts + user_copts
        cxxopts = base_cxxopts + cpp.copts + cpp.cxxopts + user_copts

    return (
        conlyopts,
        cxxopts,
        raw_swiftcopts,
        user_swiftcopts,
    )

def _process_base_compiler_opts(*, opts, skip_opts, extra_processing = None):
    """Process compiler options, skipping options that should be skipped.

    Args:
        opts: A `list` of compiler options.
        skip_opts: A `dict` of options to skip. The values are the number of
            arguments to skip.
        extra_processing: An optional function that provides further processing
            of an option. Returns `True` if the option was handled, otherwise
            `False`.

    Returns:
        A `list` of unhandled options.
    """
    unhandled_opts = []
    skip_next = 0
    previous_opt = None
    for opt in opts:
        if skip_next:
            skip_next -= 1
            continue
        if "__BAZEL_XCODE_" in opt:
            # Theses options are already handled by Xcode
            continue
        root_opt = opt.split("=")[0]
        skip_next = skip_opts.get(root_opt, 0)
        if skip_next:
            skip_next -= 1
            continue
        handled = extra_processing and extra_processing(opt, previous_opt)
        previous_opt = opt
        if handled:
            continue
        unhandled_opts.append(opt)

    return unhandled_opts

def create_opts_search_paths(quote_includes, includes, system_includes):
    """Creates a value representing search paths of a target.

    Args:
        quote_includes: A `list` of quote include paths (i.e `-iquote` values).
        includes: A `list` of include paths (i.e. `-I` values).
        system_includes: A `list` of system include paths (i.e. `-isystem`
            values).

    Returns:
        A `struct` containing the `quote_includes` and `includes` fields
        provided as arguments.
    """
    return struct(
        quote_includes = tuple(quote_includes),
        includes = tuple(includes),
        system_includes = tuple(system_includes),
    )

def merge_opts_search_paths(search_paths):
    """Merges a `list` of search paths into a single set set of search paths.

    Args:
        search_paths: A `list` of values returned from
            `create_opts_search_paths`.

    Returns:
        A value returned from `create_opts_search_paths`, with the search paths
        provided to it being the merged and deduplicated values from
        `search_paths`.
    """
    quote_includes = []
    includes = []
    system_includes = []

    for search_path in search_paths:
        quote_includes.extend(search_path.quote_includes)
        includes.extend(search_path.includes)
        system_includes.extend(search_path.system_includes)

    return create_opts_search_paths(
        quote_includes = uniq(quote_includes),
        includes = uniq(includes),
        system_includes = uniq(system_includes),
    )

def _process_conlyopts(opts):
    """Processes C compiler options.

    Args:
        opts: A `list` of C compiler options.

    Returns:
        A `tuple` containing four elements:

        *   A `list` of unhandled C compiler options.
        *   A `list` of defines parsed.
        *   A `list` of C compiler optimization levels parsed.
        *   A value returned by `create_opts_search_paths` with the parsed
            search paths.
        *   A `bool` indicting if the target has debug info enabled.
    """
    defines = []
    optimizations = []
    quote_includes = []
    includes = []
    system_includes = []
    has_debug_info = {}

    def process(opt, previous_opt):
        if previous_opt == "-isystem":
            system_includes.append(opt)
            return True
        if previous_opt == "-iquote":
            quote_includes.append(opt)
            return True
        if previous_opt == "-I":
            includes.append(opt)
            return True

        if opt.startswith("-O"):
            optimizations.append(opt)
            return True
        if opt == "-g":
            # We use a `dict` instead of setting a single value because
            # assigning to `has_debug_info` creates a new local variable instead
            # of assigning to the existing variable
            has_debug_info[True] = None
            return True
        if opt == "-isystem":
            return True
        if opt == "-iquote":
            return True
        if opt == "-I":
            return True
        if opt.startswith("-I"):
            includes.append(opt[2:])
            return True
        if opt.startswith("-D"):
            defines.append(opt[2:])
            return True
        return False

    unhandled_opts = _process_base_compiler_opts(
        opts = opts,
        skip_opts = _CC_SKIP_OPTS,
        extra_processing = process,
    )

    defines = uniq(defines)
    has_debug_info = bool(has_debug_info)

    search_paths = create_opts_search_paths(
        quote_includes = uniq(quote_includes),
        includes = uniq(includes),
        system_includes = uniq(system_includes),
    )

    return unhandled_opts, defines, optimizations, search_paths, has_debug_info

def _process_cxxopts(opts, *, build_settings):
    """Processes C++ compiler options.

    Args:
        opts: A `list` of C++ compiler options.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `tuple` containing five elements:

        *   A `list` of unhandled C++ compiler options.
        *   A `list` of defines parsed.
        *   A `list` of C++ compiler optimization levels parsed.
        *   A value returned by `_create_search_paths` with the parsed search
            paths.
        *   A `bool` indicting if the target has debug info enabled.
    """
    defines = []
    optimizations = []
    quote_includes = []
    includes = []
    system_includes = []
    has_debug_info = {}

    def process(opt, previous_opt):
        if previous_opt == "-isystem":
            system_includes.append(opt)
            return True
        if previous_opt == "-iquote":
            quote_includes.append(opt)
            return True
        if previous_opt == "-I":
            includes.append(opt)
            return True

        if opt.startswith("-O"):
            optimizations.append(opt)
            return True
        if opt.startswith("-std="):
            build_settings["CLANG_CXX_LANGUAGE_STANDARD"] = _xcode_std_value(
                opt[5:],
            )
            return True
        if opt.startswith("-stdlib="):
            build_settings["CLANG_CXX_LIBRARY"] = opt[8:]
            return True
        if opt == "-g":
            # We use a `dict` instead of setting a single value because
            # assigning to `has_debug_info` creates a new local variable instead
            # of assigning to the existing variable
            has_debug_info[True] = None
            return True
        if opt == "-isystem":
            return True
        if opt == "-iquote":
            return True
        if opt == "-I":
            return True
        if opt.startswith("-I"):
            includes.append(opt[2:])
            return True
        if opt.startswith("-D"):
            defines.append(opt[2:])
            return True
        return False

    unhandled_opts = _process_base_compiler_opts(
        opts = opts,
        skip_opts = _CC_SKIP_OPTS,
        extra_processing = process,
    )

    defines = uniq(defines)
    has_debug_info = bool(has_debug_info)

    search_paths = create_opts_search_paths(
        quote_includes = uniq(quote_includes),
        includes = uniq(includes),
        system_includes = uniq(system_includes),
    )

    return unhandled_opts, defines, optimizations, search_paths, has_debug_info

def _process_copts(*, conlyopts, cxxopts, build_settings):
    """Processes C and C++ compiler options.

    Args:
        conlyopts: A `list` of C compiler options.
        cxxopts: A `list` of C++ compiler options.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `conlyopts` and `cxxopts`.

    Returns:
        A `tuple` containing three elements:

        *   A `list` of unhandled C compiler options.
        *   A `list` of unhandled C++ compiler options.
        *   A value returned by `_create_search_paths` with the parsed search
            paths.
        *   A `bool` indicting if the target has debug info enabled for C.
        *   A `bool` indicting if the target has debug info enabled for C++.
    """
    (
        conlyopts,
        conly_defines,
        conly_optimizations,
        conly_search_paths,
        c_has_debug_info,
    ) = _process_conlyopts(conlyopts)
    (
        cxxopts,
        cxx_defines,
        cxx_optimizations,
        cxx_search_paths,
        cxx_has_debug_info,
    ) = _process_cxxopts(
        cxxopts,
        build_settings = build_settings,
    )

    # Calculate GCC_OPTIMIZATION_LEVEL, preserving C/C++ specific settings
    if conly_optimizations:
        default_conly_optimization = conly_optimizations[0]
        conly_optimizations = conly_optimizations[1:]
    else:
        default_conly_optimization = "-O0"
    if cxx_optimizations:
        default_cxx_optimization = cxx_optimizations[0]
        cxx_optimizations = cxx_optimizations[1:]
    else:
        default_cxx_optimization = "-O0"
    if default_conly_optimization == default_cxx_optimization:
        gcc_optimization = default_conly_optimization
    else:
        gcc_optimization = "-O0"
        conly_optimizations = [default_conly_optimization] + conly_optimizations
        cxx_optimizations = [default_cxx_optimization] + cxx_optimizations
    build_settings["GCC_OPTIMIZATION_LEVEL"] = gcc_optimization[2:]

    # Calculate GCC_PREPROCESSOR_DEFINITIONS, from common conly and cxx defines
    defines = []
    for conly_define, cxx_define in zip(conly_defines, cxx_defines):
        if conly_define != cxx_define:
            break
        defines.append(conly_define)

    set_if_true(
        build_settings,
        "GCC_PREPROCESSOR_DEFINITIONS",
        defines,
    )

    conly_defines = [
        "-D{}".format(define)
        for define in conly_defines[len(defines):]
    ]
    cxx_defines = [
        "-D{}".format(define)
        for define in cxx_defines[len(defines):]
    ]

    return (
        conly_optimizations + conly_defines + conlyopts,
        cxx_optimizations + cxx_defines + cxxopts,
        conly_search_paths,
        cxx_search_paths,
        c_has_debug_info,
        cxx_has_debug_info,
    )

def _process_swiftopts(
        *,
        full_swiftcopts,
        user_swiftcopts,
        compilation_mode,
        objc_fragment,
        cc_info,
        package_bin_dir,
        build_settings):
    """Processes Swift compiler options.

    Args:
        full_swiftcopts: A `list` of Swift compiler options.
        user_swiftcopts: A `list` of user-provided Swift compiler options.
        compilation_mode: The current compilation mode.
        objc_fragment: The `objc` configuration fragment.
        cc_info: The `CcInfo` provider for the target.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `tuple` containing three elements:

        *   A `list` of unhandled Swift compiler options.
        *   A value returned by `_create_search_paths` with the parsed search
            paths.
        *   A `bool` indicting if the target has debug info enabled.
    """
    swiftcopts, raw_has_debug_info = _process_full_swiftcopts(
        full_swiftcopts,
        compilation_mode = compilation_mode,
        objc_fragment = objc_fragment,
        cc_info = cc_info,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    swift_search_paths, user_has_debug_info = _process_user_swiftcopts(
        user_swiftcopts,
    )

    has_debug_info = raw_has_debug_info or user_has_debug_info

    return swiftcopts, swift_search_paths, has_debug_info

def _process_full_swiftcopts(
        opts,
        *,
        compilation_mode,
        objc_fragment,
        cc_info,
        package_bin_dir,
        build_settings):
    """Processes the full Swift compiler options (including Bazel ones).

    Args:
        opts: A `list` of Swift compiler options.
        compilation_mode: The current compilation mode.
        objc_fragment: The `objc` configuration fragment.
        cc_info: The `CcInfo` provider for the target.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `tuple` containing two elements:

        *   A `list` of unhandled Swift compiler options.
        *   A `bool` indicting if the target has debug info enabled.
    """

    # Xcode needs a value for SWIFT_VERSION, so we set it to "5" by default.
    # We will have to figure out a way to detect what the default is before
    # Swift 6 (which will probably have a new language version).
    build_settings["SWIFT_VERSION"] = "5"

    # Default to not creating the Swift generated header.
    build_settings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = ""

    defines = []
    has_debug_info = {}

    def process(opt, previous_opt):
        if previous_opt == "-emit-objc-header-path":
            if not opt.startswith(package_bin_dir):
                fail("""\
-emit-objc-header-path must be in bin dir of the target. {} is not \
under {}""".format(opt, package_bin_dir))
            header_name = opt[len(package_bin_dir) + 1:]
            build_settings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = header_name
            return True

        if opt.startswith("-O"):
            build_settings["SWIFT_OPTIMIZATION_LEVEL"] = opt
            return True
        if opt.startswith("-I"):
            return True
        if opt == "-g":
            # We use a `dict` instead of setting a single value because
            # assigning to `has_debug_info` creates a new local variable instead
            # of assigning to the existing variable
            has_debug_info[True] = None
            return True
        if opt == "-enable-testing":
            build_settings["ENABLE_TESTABILITY"] = True
            return True
        if opt == "-application-extension":
            build_settings["APPLICATION_EXTENSION_API_ONLY"] = True
            return True
        compilation_mode = _SWIFT_COMPILATION_MODE_OPTS.get(opt, "")
        if compilation_mode:
            build_settings["SWIFT_COMPILATION_MODE"] = compilation_mode
            return True
        if opt.startswith("-swift-version="):
            build_settings["SWIFT_VERSION"] = opt[15:]
            return True
        if opt == "-emit-objc-header-path":
            # Handled in `previous_opt` check above
            return True
        if opt.startswith("-D"):
            defines.append(opt[2:])
            return True
        if not opt.startswith("-") and opt.endswith(".swift"):
            # These are the files to compile, not options. They are seen here
            # because of the way we collect Swift compiler options. Ideally in
            # the future we could collect Swift compiler options similar to how
            # we collect C and C++ compiler options.
            return True
        return False

    # Xcode's default is `-O` when not set, so minimally set it to `-Onone`,
    # which matches swiftc's default.
    build_settings["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone"

    unhandled_opts = _process_base_compiler_opts(
        opts = opts,
        skip_opts = _SWIFTC_SKIP_OPTS,
        extra_processing = process,
    )

    has_debug_info = bool(has_debug_info)

    # If we have swift flags, then we need to add in the PCM flags
    if opts:
        unhandled_opts = collections.before_each(
            "-Xcc",
            swift_pcm_copts(
                compilation_mode = compilation_mode,
                objc_fragment = objc_fragment,
                cc_info = cc_info,
            ),
        ) + unhandled_opts

    set_if_true(
        build_settings,
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
        # Eliminate duplicates
        " ".join(uniq(defines)),
    )

    return unhandled_opts, has_debug_info

def _process_user_swiftcopts(opts):
    """Processes user-provided Swift compiler options.

    Args:
        opts: A `list` of Swift compiler options.

    Note: any flag processed here needs to be filtered from processing in
    `_process_full_swiftcopts`.

    Returns:
        A `tuple` containing two elements:

        *   A `list` of search paths.
        *   A `bool` indicting if the target has debug info enabled.
    """

    quote_includes = []
    includes = []
    system_includes = []
    has_debug_info = {}

    def process(opt, previous_opt):
        # TODO: handle the format "-Xcc -iquote -Xcc path"
        if previous_opt == "-Xcc" and opt.startswith("-isystem"):
            system_includes.append(opt[8:])
            return True
        if previous_opt == "-Xcc" and opt.startswith("-iquote"):
            quote_includes.append(opt[7:])
            return True
        if previous_opt == "-Xcc" and opt.startswith("-I"):
            includes.append(opt[2:])
            return True

        if opt == "-Xcc" or previous_opt == "-Xcc":
            return True
        if opt == "-g":
            # We use a `dict` instead of setting a single value because
            # assigning to `has_debug_info` creates a new local variable instead
            # of assigning to the existing variable
            has_debug_info[True] = None
            return True
        return False

    _process_base_compiler_opts(
        opts = opts,
        skip_opts = {},  # Empty in order to process all user opts.
        extra_processing = process,
    )

    has_debug_info = bool(has_debug_info)

    search_paths = create_opts_search_paths(
        quote_includes = uniq(quote_includes),
        includes = uniq(includes),
        system_includes = uniq(system_includes),
    )

    return search_paths, has_debug_info

def swift_pcm_copts(*, compilation_mode, objc_fragment, cc_info):
    base_pcm_flags = _swift_command_line_objc_copts(
        compilation_mode = compilation_mode,
        objc_fragment = objc_fragment,
    )
    pcm_defines = [
        "-D{}".format(define)
        for define in (
            cc_info.compilation_context.defines.to_list() if cc_info else []
        )
    ]

    return base_pcm_flags + pcm_defines

# Lifted from rules_swift, to mimic its behavior
def _swift_command_line_objc_copts(*, compilation_mode, objc_fragment):
    """Returns copts that should be passed to `clang` from the `objc` fragment.

    Args:
        compilation_mode: The current compilation mode.
        objc_fragment: The `objc` configuration fragment.

    Returns:
        A list of `clang` copts, each of which is preceded by `-Xcc` so that
        they can be passed through `swiftc` to its underlying ClangImporter
        instance.
    """

    # In general, every compilation mode flag from native `objc_*` rules should
    # be passed, but `-g` seems to break Clang module compilation. Since this
    # flag does not make much sense for module compilation and only touches
    # headers, it's ok to omit.
    # TODO: These flags were originally being set by Bazel's legacy
    # hardcoded Objective-C behavior, which has been migrated to crosstool. In
    # the long term, we should query crosstool for the flags we're interested in
    # and pass those to ClangImporter, and do this across all platforms. As an
    # immediate short-term workaround, we preserve the old behavior by passing
    # the exact set of flags that Bazel was originally passing if the list we
    # get back from the configuration fragment is empty.
    legacy_copts = objc_fragment.copts_for_current_compilation_mode
    if not legacy_copts:
        if compilation_mode == "dbg":
            legacy_copts = [
                "-O0",
                "-DDEBUG=1",
                "-fstack-protector",
                "-fstack-protector-all",
            ]
        elif compilation_mode == "opt":
            legacy_copts = [
                "-Os",
                "-DNDEBUG=1",
                "-Wno-unused-variable",
                "-Winit-self",
                "-Wno-extra",
            ]

    clang_copts = objc_fragment.copts + legacy_copts
    return [copt for copt in clang_copts if copt != "-g"]

def _process_compiler_opts(
        *,
        conlyopts,
        cxxopts,
        full_swiftcopts,
        compilation_mode,
        cpp_fragment,
        objc_fragment,
        cc_info,
        user_swiftcopts,
        package_bin_dir,
        build_settings):
    """Processes compiler options.

    Args:
        conlyopts: A `list` of C compiler options.
        cxxopts: A `list` of C++ compiler options.
        full_swiftcopts: A `list` of Swift compiler options.
        user_swiftcopts: A `list` of user-provided Swift compiler options.
        compilation_mode: The current compilation mode.
        cpp_fragment: The `cpp` configuration fragment.
        objc_fragment: The `objc` configuration fragment.
        cc_info: The `CcInfo` provider for the target.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed the `conlyopts`, `cxxopts`, and
            `swiftcopts` lists.

    Returns:
        A `struct` containing the following fields:

        *   `quotes_includes`: A `list` of quote include paths parsed.
        *   `includes`: A `list` of include paths parsed.
    """
    has_copts = conlyopts or cxxopts

    (
        conlyopts,
        cxxopts,
        conly_search_paths,
        cxx_search_paths,
        c_has_debug_info,
        cxx_has_debug_info,
    ) = _process_copts(
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        build_settings = build_settings,
    )
    swiftcopts, swift_search_paths, swift_has_debug_info = _process_swiftopts(
        full_swiftcopts = full_swiftcopts,
        user_swiftcopts = user_swiftcopts,
        compilation_mode = compilation_mode,
        objc_fragment = objc_fragment,
        cc_info = cc_info,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    has_debug_info = {}
    if has_copts:
        has_debug_info[c_has_debug_info] = None
        has_debug_info[cxx_has_debug_info] = None
    if full_swiftcopts:
        has_debug_info[swift_has_debug_info] = None

    has_debug_infos = has_debug_info.keys()

    if len(has_debug_infos) == 1:
        # We don't set "DEBUG_INFORMATION_FORMAT" for "dwarf"-with-dsym",
        # as that's Xcode's default
        if not has_debug_infos[0]:
            build_settings["DEBUG_INFORMATION_FORMAT"] = ""
        elif not cpp_fragment.apple_generate_dsym:
            build_settings["DEBUG_INFORMATION_FORMAT"] = "dwarf"
    else:
        build_settings["DEBUG_INFORMATION_FORMAT"] = ""
        if c_has_debug_info:
            conlyopts = ["-g"] + conlyopts
        if cxx_has_debug_info:
            cxxopts = ["-g"] + cxxopts
        if swift_has_debug_info:
            swiftcopts = ["-g"] + swiftcopts

    # TODO: Split out `WARNING_CFLAGS`? (Must maintain order, and only ones that apply to both c and cxx)

    set_if_true(
        build_settings,
        "OTHER_CFLAGS",
        tuple(conlyopts),
    )
    set_if_true(
        build_settings,
        "OTHER_CPLUSPLUSFLAGS",
        tuple(cxxopts),
    )
    set_if_true(
        build_settings,
        "OTHER_SWIFT_FLAGS",
        " ".join(swiftcopts),
    )

    return merge_opts_search_paths([
        conly_search_paths,
        cxx_search_paths,
        swift_search_paths,
    ])

def _process_target_compiler_opts(
        *,
        ctx,
        target,
        package_bin_dir,
        build_settings):
    """Processes the compiler options for a target.

    Args:
        ctx: The aspect context.
        target: The `Target` that the compiler options will be retrieved from.
        package_bin_dir: The package directory for `target` within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from the target's compiler options.

    Returns:
        A `struct` containing the following fields:

        *   `quotes_includes`: A `list` of quote include paths parsed.
        *   `includes`: A `list` of include paths parsed.
    """
    (
        conlyopts,
        cxxopts,
        full_swiftcopts,
        user_swiftcopts,
    ) = _get_unprocessed_compiler_opts(
        ctx = ctx,
        target = target,
    )
    return _process_compiler_opts(
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        full_swiftcopts = full_swiftcopts,
        user_swiftcopts = user_swiftcopts,
        compilation_mode = ctx.var["COMPILATION_MODE"],
        cpp_fragment = ctx.fragments.cpp,
        objc_fragment = ctx.fragments.objc,
        cc_info = target[CcInfo] if CcInfo in target else None,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

# Utility

def _expand_locations(*, ctx, values, targets = []):
    """Expands the `$(location)` placeholders in each of the given values.

    Args:
        ctx: The aspect context.
        values: A `list` of strings, which may contain `$(location)`
            placeholders.
        targets: A `list` of additional targets (other than the calling rule's
            `deps`) that should be searched for substitutable labels.

    Returns:
        A `list` of strings with any `$(location)` placeholders filled in.
    """
    return [ctx.expand_location(value, targets) for value in values]

def _expand_make_variables(*, ctx, values, attribute_name):
    """Expands all references to Make variables in each of the given values.

    Args:
        ctx: The aspect context.
        values: A `list` of strings, which may contain Make variable
            placeholders.
        attribute_name: The attribute name string that will be presented in the
            console when an error occurs.

    Returns:
        A `list` of strings with Make variables placeholders filled in.
    """
    return [
        ctx.expand_make_variables(attribute_name, value, {})
        for value in values
    ]

def _xcode_std_value(std):
    """Converts a '-std' option value to an Xcode recognized value."""
    if std.endswith("11"):
        # Xcode encodes "c++11" as "c++0x"
        return std[:-2] + "0x"
    return std

# API

def process_opts(*, ctx, target, package_bin_dir, build_settings):
    """Processes the compiler options for a target.

    Args:
        ctx: The aspect context.
        target: The `Target` that the compiler and linker options will be
            retrieved from.
        package_bin_dir: The package directory for `target` within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from the compiler and linker options.

    Returns:
        A `struct` containing the following fields:

        *   `quotes_includes`: A `list` of quote include paths parsed.
        *   `includes`: A `list` of include paths parsed.
    """
    search_paths = _process_target_compiler_opts(
        ctx = ctx,
        target = target,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )
    return search_paths

# These functions are exposed only for access in unit tests.
testable = struct(
    process_compiler_opts = _process_compiler_opts,
)
