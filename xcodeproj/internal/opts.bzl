"""Functions for processing compiler and linker options."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
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
    "-Xwrapped-swift": 1,
    "-debug-prefix-map": 2,
    "-emit-module-path": 2,
    "-emit-object": 1,
    "-emit-symbol-graph-dir": 2,
    "-enable-bare-slash-regex": 1,
    "-enable-batch-mode": 1,
    "-file-prefix-map": 2,
    # TODO: See if we need to support this
    "-gline-tables-only": 1,
    "-index-ignore-system-modules": 1,
    "-index-store-path": 2,
    "-module-cache-path": 2,
    "-module-name": 2,
    "-num-threads": 2,
    "-output-file-map": 2,
    "-parse-as-library": 1,
    "-sdk": 2,
    "-target": 2,
}

_SWIFTC_SKIP_COMPOUND_OPTS = {
    "-Xfrontend": {
        "-color-diagnostics": 1,
        "-emit-symbol-graph": 1,
        "-no-clang-module-breadcrumbs": 1,
        "-no-serialize-debugging-options": 1,
        "-serialize-debugging-options": 1,
    },
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

def _get_unprocessed_compiler_opts(*, ctx, build_mode, target):
    """Returns the unprocessed compiler options for the given target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        target: The `Target` that the compiler options will be retrieved from.

    Returns:
        A `tuple` containing three elements:

        *   A `list` of C compiler options.
        *   A `list` of C++ compiler options.
        *   A `list` of Swift compiler options.
    """

    # TODO: Handle perfileopts somehow?

    conlyopts = []
    cxxopts = []
    swiftcopts = []

    for action in target.actions:
        if action.mnemonic == "SwiftCompile":
            # First two arguments are "worker" and "swiftc"
            swiftcopts = action.argv[2:]

    if not swiftcopts and CcInfo in target:
        cc_info = target[CcInfo]
        compilation_context = cc_info.compilation_context
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
            include_directories = compilation_context.includes,
            quote_include_directories = compilation_context.quote_includes,
            system_include_directories = compilation_context.system_includes,
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

        if build_mode == "xcode":
            for opt in conlyopts + cxxopts:
                if opt.startswith("-ivfsoverlay`"):
                    fail("""\
Using VFS overlays with `build_mode = "xcode"` is unsupported.
""")

    return (
        conlyopts,
        cxxopts,
        swiftcopts,
    )

def _process_base_compiler_opts(
        *,
        opts,
        skip_opts,
        compound_skip_opts = {},
        extra_processing = None):
    """Process compiler options, skipping options that should be skipped.

    Args:
        opts: A `list` of compiler options.
        skip_opts: A `dict` of options to skip. The values are the number of
            arguments to skip.
        compound_skip_opts: A `dict` of options that we might skip if further
            options match. The values are `dict`s of options to skip, where the
            keys and values are handled the same as `skip_opts`, except 1 is
            added to whatever is returned for the skip number.
        extra_processing: An optional function that provides further processing
            of an option. Returns the processed opt, or `None` if it as handled
            another way (like being added to build settings).

    Returns:
        A `list` of unhandled options.
    """
    processed_opts = []
    skip_next = 0
    previous_opt = None
    previous_frontend_opt = None
    for idx, opt in enumerate(opts):
        if skip_next:
            skip_next -= 1
            continue
        if (opt == "-F__BAZEL_XCODE_SDKROOT__/Developer/Library/Frameworks" or
            opt == "-F__BAZEL_XCODE_SDKROOT__/System/Library/Frameworks" or
            opt.startswith("-F__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/") or
            opt.startswith("-I__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/")):
            # Theses options are already handled by Xcode
            continue
        root_opt = opt.split("=")[0]

        skip_next = skip_opts.get(root_opt, 0)
        if skip_next:
            skip_next -= 1
            continue

        compound_skip_next = compound_skip_opts.get(root_opt)
        if compound_skip_next:
            skip_next = compound_skip_next.get(opts[idx + 1], 0)
            if skip_next:
                # No need to decrement 1, since we need to skip the first opt
                continue

        # Use Xcode set `DEVELOPER_DIR`
        opt = opt.replace("__BAZEL_XCODE_DEVELOPER_DIR__", "$(DEVELOPER_DIR)")

        # Use Xcode set `SDKROOT`
        opt = opt.replace("__BAZEL_XCODE_SDKROOT__", "$(SDKROOT)")

        if opt != "-Xfrontend":
            previous_vfsoverlay_opt = previous_frontend_opt or previous_opt

            # -vfsoverlay doesn't apply `-working_directory=`, so we need to
            # prefix it ourselves
            _, opt_prefix, suffix = opt.partition("-vfsoverlay")
            if not opt_prefix:
                _, opt_prefix, suffix = opt.partition("-ivfsoverlay")
            if suffix:
                if not suffix.startswith("/"):
                    opt = opt_prefix + "$(PROJECT_DIR)/" + suffix
            elif (previous_vfsoverlay_opt == "-vfsoverlay" or
                  previous_vfsoverlay_opt == "-ivfsoverlay"):
                if not opt.startswith("/"):
                    opt = "$(PROJECT_DIR)/" + opt

        processed_opt = (
            extra_processing and
            extra_processing(opt, previous_opt)
        )

        if previous_opt == "-Xfrontend":
            previous_frontend_opt = opt
        elif opt != "-Xfrontend":
            previous_frontend_opt = None
        previous_opt = opt

        opt = processed_opt
        if not opt:
            continue

        processed_opts.append(opt)

    return processed_opts

def create_opts_search_paths(quote_includes, includes, system_includes):
    """Creates a value representing search paths of a target.

    Args:
        quote_includes: A `list` of quote include paths (i.e `-iquote` values).
        includes: A `list` of include paths (i.e. `-I` values).
        system_includes: A `list` of system include paths (i.e. `-isystem`
            values).

    Returns:
        A `struct` containing the `quote_includes`, `includes`, and
        `system_includes` fields provided as arguments.
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

def _process_conlyopts(opts, *, build_settings):
    """Processes C compiler options.

    Args:
        opts: A `list` of C compiler options.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

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
            return None
        if previous_opt == "-iquote":
            quote_includes.append(opt)
            return None
        if previous_opt == "-I":
            includes.append(opt)
            return None

        if opt.startswith("-O"):
            optimizations.append(opt)
            return None
        if opt == "-g":
            # We use a `dict` instead of setting a single value because
            # assigning to `has_debug_info` creates a new local variable instead
            # of assigning to the existing variable
            has_debug_info[True] = None
            return None
        if opt == "-isystem":
            return None
        if opt == "-iquote":
            return None
        if opt == "-I":
            return None
        if opt.startswith("-isystem"):
            system_includes.append(opt[8:])
            return None
        if opt.startswith("-iquote"):
            quote_includes.append(opt[7:])
            return None
        if opt.startswith("-I"):
            includes.append(opt[2:])
            return None
        if opt.startswith("-D"):
            value = opt[2:]
            if value.startswith("OBJC_OLD_DISPATCH_PROTOTYPES"):
                if value.endswith("=1"):
                    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = False
                elif value.endswith("=1"):
                    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = True
                return None
            defines.append(value)
            return None
        return opt

    processed_opts = _process_base_compiler_opts(
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

    return processed_opts, defines, optimizations, search_paths, has_debug_info

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
            return None
        if previous_opt == "-iquote":
            quote_includes.append(opt)
            return None
        if previous_opt == "-I":
            includes.append(opt)
            return None

        if opt.startswith("-O"):
            optimizations.append(opt)
            return None
        if opt == "-g":
            # We use a `dict` instead of setting a single value because
            # assigning to `has_debug_info` creates a new local variable instead
            # of assigning to the existing variable
            has_debug_info[True] = None
            return None
        if opt == "-isystem":
            return None
        if opt == "-iquote":
            return None
        if opt == "-I":
            return None
        if opt.startswith("-isystem"):
            system_includes.append(opt[8:])
            return None
        if opt.startswith("-iquote"):
            quote_includes.append(opt[7:])
            return None
        if opt.startswith("-I"):
            includes.append(opt[2:])
            return None
        if opt.startswith("-D"):
            value = opt[2:]
            if value.startswith("OBJC_OLD_DISPATCH_PROTOTYPES"):
                if value.endswith("=1"):
                    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = False
                return None
            defines.append(value)
            return None
        return opt

    processed_opts = _process_base_compiler_opts(
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

    return processed_opts, defines, optimizations, search_paths, has_debug_info

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
        *   A value returned by `create_opts_search_paths` with the parsed
            search paths.
        *   A `bool` indicting if the target has debug info enabled for C.
        *   A `bool` indicting if the target has debug info enabled for C++.
    """
    (
        conlyopts,
        conly_defines,
        conly_optimizations,
        conly_search_paths,
        c_has_debug_info,
    ) = _process_conlyopts(conlyopts, build_settings = build_settings)
    (
        cxxopts,
        cxx_defines,
        cxx_optimizations,
        cxx_search_paths,
        cxx_has_debug_info,
    ) = _process_cxxopts(cxxopts, build_settings = build_settings)

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

def _process_swiftcopts(
        opts,
        *,
        build_mode,
        package_bin_dir,
        build_settings):
    """Processes the full Swift compiler options (including Bazel ones).

    Args:
        opts: A `list` of Swift compiler options.
        build_mode: See `xcodeproj.build_mode`.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `tuple` containing three elements:

        *   A `list` of processed Swift compiler options.
        *   A value returned by `create_opts_search_paths` with the parsed
            search paths.
        *   A `bool` indicting if the target has debug info enabled.
    """

    # Xcode needs a value for SWIFT_VERSION, so we set it to "5.0" by default.
    # We will have to figure out a way to detect what the default is before
    # Swift 6 (which will probably have a new language version).
    build_settings["SWIFT_VERSION"] = "5.0"

    # Default to not creating the Swift generated header.
    build_settings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = ""

    defines = []
    quote_includes = []
    includes = []
    system_includes = []
    has_debug_info = {}

    def process(opt, previous_opt):
        # TODO: handle the format "-Xcc -iquote -Xcc path"
        if opt.startswith("-isystem"):
            path = opt[8:]
            if previous_opt == "-Xcc":
                system_includes.append(path)
            if build_mode == "xcode":
                return "-isystem" + _process_copt_possible_path(path)
            return opt
        if opt.startswith("-iquote"):
            path = opt[7:]
            if previous_opt == "-Xcc":
                quote_includes.append(path)
            if build_mode == "xcode":
                return "-iquote" + _process_copt_possible_path(path)
            return opt
        if opt.startswith("-I"):
            path = opt[2:]
            if previous_opt == "-Xcc":
                includes.append(path)
            if build_mode == "xcode":
                return "-I" + _process_copt_possible_path(path)
            return opt
        if previous_opt == "-Xcc":
            # We do this check here, to prevent the `-O` and `-D` logic below
            # from incorrectly detecting this situation
            if build_mode == "xcode":
                return _process_copt_for_paths(opt)
            return opt

        if previous_opt == "-emit-objc-header-path":
            if not opt.startswith(package_bin_dir):
                fail("""\
-emit-objc-header-path must be in bin dir of the target. {} is not \
under {}""".format(opt, package_bin_dir))
            header_name = opt[len(package_bin_dir) + 1:]
            build_settings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = header_name
            return None

        if opt.startswith("-O"):
            build_settings["SWIFT_OPTIMIZATION_LEVEL"] = opt
            return None
        if build_mode == "xcode" and opt.startswith("-vfsoverlay"):
            fail("""\
Using VFS overlays with `build_mode = "xcode"` is unsupported.
""")
        if opt == "-g":
            # We use a `dict` instead of setting a single value because
            # assigning to `has_debug_info` creates a new local variable instead
            # of assigning to the existing variable
            has_debug_info[True] = None
            return None
        if opt == "-enable-testing":
            build_settings["ENABLE_TESTABILITY"] = True
            return None
        if opt == "-application-extension":
            build_settings["APPLICATION_EXTENSION_API_ONLY"] = True
            return None
        compilation_mode = _SWIFT_COMPILATION_MODE_OPTS.get(opt, "")
        if compilation_mode:
            build_settings["SWIFT_COMPILATION_MODE"] = compilation_mode
            return None
        if opt.startswith("-swift-version="):
            build_settings["SWIFT_VERSION"] = opt[15:]
            return None
        if opt == "-emit-objc-header-path":
            # Handled in `previous_opt` check above
            return None
        if opt.startswith("-strict-concurrency="):
            build_settings["SWIFT_STRICT_CONCURRENCY"] = opt[20:]
            return None
        if opt.startswith("-D"):
            defines.append(opt[2:])
            return None
        if not opt.startswith("-") and opt.endswith(".swift"):
            # These are the files to compile, not options. They are seen here
            # because of the way we collect Swift compiler options. Ideally in
            # the future we could collect Swift compiler options similar to how
            # we collect C and C++ compiler options.
            return None

        if build_mode == "xcode":
            return _process_copt_for_paths(opt)
        return opt

    # Xcode's default is `-O` when not set, so minimally set it to `-Onone`,
    # which matches swiftc's default.
    build_settings["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone"

    processed_opts = _process_base_compiler_opts(
        opts = opts,
        skip_opts = _SWIFTC_SKIP_OPTS,
        compound_skip_opts = _SWIFTC_SKIP_COMPOUND_OPTS,
        extra_processing = process,
    )

    has_debug_info = bool(has_debug_info)

    search_paths = create_opts_search_paths(
        quote_includes = uniq(quote_includes),
        includes = uniq(includes),
        system_includes = uniq(system_includes),
    )

    set_if_true(
        build_settings,
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
        # Eliminate duplicates
        " ".join(uniq(defines)),
    )

    return processed_opts, search_paths, has_debug_info

def _process_copt_for_paths(copt):
    components = copt.split("=", 1)
    if len(components) > 1:
        return "{}={}".format(
            components[0],
            _process_copt_possible_path(components[1]),
        )
    return _process_copt_possible_path(copt)

def _process_copt_possible_path(copt):
    if copt == "bazel-out" or copt.startswith("bazel-out/"):
        return "$(BAZEL_OUT){}".format(copt[9:])
    if copt == "external" or copt.startswith("external/"):
        return "$(BAZEL_EXTERNAL){}".format(copt[8:])
    return copt

def swift_pcm_copts(*, compilation_mode, objc_fragment, cc_info):
    base_pcm_flags = _swift_command_line_objc_copts(
        compilation_mode = compilation_mode,
        objc_fragment = objc_fragment,
    )
    pcm_defines = [
        "-D{}".format(define.replace("\\", "\\\\").replace('"', '\\"'))
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
        A `list` of `clang` copts, each of which is preceded by `-Xcc` so that
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
        swiftcopts,
        build_mode,
        cpp_fragment,
        package_bin_dir,
        build_settings):
    """Processes compiler options.

    Args:
        conlyopts: A `list` of C compiler options.
        cxxopts: A `list` of C++ compiler options.
        swiftcopts: A `list` of Swift compiler options.
        build_mode: See `xcodeproj.build_mode`.
        cpp_fragment: The `cpp` configuration fragment.
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

    # Xcode's default for `ENABLE_STRICT_OBJC_MSGSEND` doesn't match its new
    # project default, so we need to set it explicitly
    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = True

    has_copts = conlyopts or cxxopts
    has_swiftcop = swiftcopts

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
    swiftcopts, swift_search_paths, swift_has_debug_info = _process_swiftcopts(
        opts = swiftcopts,
        build_mode = build_mode,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    has_debug_info = {}
    if has_copts:
        has_debug_info[c_has_debug_info] = None
        has_debug_info[cxx_has_debug_info] = None
    if has_swiftcop:
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
        build_mode,
        target,
        package_bin_dir,
        build_settings):
    """Processes the compiler options for a target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
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
        swiftcopts,
    ) = _get_unprocessed_compiler_opts(
        ctx = ctx,
        build_mode = build_mode,
        target = target,
    )
    return _process_compiler_opts(
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        swiftcopts = swiftcopts,
        build_mode = build_mode,
        cpp_fragment = ctx.fragments.cpp,
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

# API

def process_opts(*, ctx, build_mode, target, package_bin_dir, build_settings):
    """Processes the compiler options for a target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
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
        build_mode = build_mode,
        target = target,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )
    return search_paths

# These functions are exposed only for access in unit tests.
testable = struct(
    process_compiler_opts = _process_compiler_opts,
)
