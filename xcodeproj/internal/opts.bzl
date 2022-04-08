"""Functions for processing compiler and linker options."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
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
        *   A `list` of Swift compiler options.
    """
    cc_toolchain = find_cpp_toolchain(ctx)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features + _UNSUPPORTED_CC_FEATURES,
    )
    variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        user_compile_flags = [],
    )

    base_copts = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = "c-compile",
        variables = variables,
    )
    base_cxxopts = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = "c++-compile",
        variables = variables,
    )

    # TODO: Handle perfileopts somehow?

    if SwiftInfo in target:
        # Rule level swiftcopts are included in action.argv below
        rule_copts = []
    elif CcInfo in target:
        rule_copts = getattr(ctx.rule.attr, "copts", [])
        rule_copts = _expand_make_variables(
            ctx = ctx,
            values = rule_copts,
            attribute_name = "copts",
        )
    else:
        rule_copts = []

    raw_swiftcopts = []
    for action in target.actions:
        if action.mnemonic == "SwiftCompile":
            # First two arguments are "worker" and "swiftc"
            raw_swiftcopts = action.argv[2:]

    cpp = ctx.fragments.cpp

    return (
        base_copts + cpp.copts + cpp.conlyopts + rule_copts,
        base_cxxopts + cpp.copts + cpp.cxxopts + rule_copts,
        raw_swiftcopts,
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

def create_opts_search_paths(quote_includes, includes):
    """Creates a value representing search paths of a target.

    Args:
        quote_includes: A `list` of quote include paths (i.e `-iquote` values).
        includes: A `list` of include paths (i.e. `-I` values).

    Returns:
        A `struct` containing the `quote_includes` and `includes` fields
        provided as arguments.
    """
    return struct(
        quote_includes = quote_includes,
        includes = includes,
    )

def merge_opts_search_paths(search_paths):
    """Merges a `list` of search paths into a single set set of search paths.

    Args:
        search_paths: A `list` of values returned from `_create_search_paths()`.

    Returns:
        A value returned from `_create_search_paths()`, with the search paths
        provided to it being the merged and deduplicated values from
        `search_paths`.
    """
    quote_includes = []
    includes = []

    for search_path in search_paths:
        quote_includes.extend(search_path.quote_includes)
        includes.extend(search_path.includes)

    return create_opts_search_paths(
        quote_includes = uniq(quote_includes),
        includes = uniq(includes),
    )

def _process_conlyopts(opts):
    """Processes C compiler options.

    Args:
        opts: A `list` of C compiler options.

    Returns:
        A `tuple` containing four elements:

        *   A `list` of unhandled C compiler options.
        *   A `list` of C compiler optimization levels parsed.
        *   A value returned by `_create_search_paths()` with the parsed search
            paths.
    """
    optimizations = []
    quote_includes = []
    includes = []

    def process(opt, previous_opt):
        if previous_opt == "-iquote":
            quote_includes.append(opt)
            return True
        if previous_opt == "-I":
            includes.append(opt)
            return True

        if opt.startswith("-O"):
            optimizations.append(opt)
            return True
        if opt == "-iquote":
            return True
        if opt == "-I":
            return True
        if opt.startswith("-I"):
            includes.append(opt[2:])
            return True
        return False

    unhandled_opts = _process_base_compiler_opts(
        opts = opts,
        skip_opts = _CC_SKIP_OPTS,
        extra_processing = process,
    )

    search_paths = create_opts_search_paths(
        quote_includes = uniq(quote_includes),
        includes = uniq(includes),
    )

    return unhandled_opts, optimizations, search_paths

def _process_cxxopts(opts, *, build_settings):
    """Processes C++ compiler options.

    Args:
        opts: A `list` of C++ compiler options.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `tuple` containing four elements:

        *   A `list` of unhandled C++ compiler options.
        *   A `list` of C++ compiler optimization levels parsed.
        *   A value returned by `_create_search_paths()` with the parsed search
            paths.
    """
    optimizations = []
    quote_includes = []
    includes = []

    def process(opt, previous_opt):
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
        if opt == "-iquote":
            return True
        if opt == "-I":
            return True
        if opt.startswith("-I"):
            includes.append(opt[2:])
            return True
        return False

    unhandled_opts = _process_base_compiler_opts(
        opts = opts,
        skip_opts = _CC_SKIP_OPTS,
        extra_processing = process,
    )

    search_paths = create_opts_search_paths(
        quote_includes = uniq(quote_includes),
        includes = uniq(includes),
    )

    return unhandled_opts, optimizations, search_paths

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
        *   A value returned by `_create_search_paths()` with the parsed search
            paths.
    """
    (
        conlyopts,
        conly_optimizations,
        conly_search_paths,
    ) = _process_conlyopts(conlyopts)
    (
        cxxopts,
        cxx_optimizations,
        cxx_search_paths,
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
    if gcc_optimization != "-O0":
        build_settings["GCC_OPTIMIZATION_LEVEL"] = gcc_optimization[2:]

    return (
        conly_optimizations + conlyopts,
        cxx_optimizations + cxxopts,
        merge_opts_search_paths([conly_search_paths, cxx_search_paths]),
    )

def _process_swiftcopts(opts, *, package_bin_dir, build_settings):
    """Processes Swift compiler options.

    Args:
        opts: A `list` of Swift compiler options.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `list` of unhandled Swift compiler options.
    """

    # Xcode needs a value for SWIFT_VERSION, so we set it to "5" by default.
    # We will have to figure out a way to detect what the default is before
    # Swift 6 (which will probably have a new language version).
    build_settings["SWIFT_VERSION"] = "5"

    # Default to not creating the Swift generated header.
    build_settings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = ""

    defines = []

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
        if opt == "-enable-testing":
            build_settings["ENABLE_TESTABILITY"] = True
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

    set_if_true(
        build_settings,
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
        # Eliminate duplicates
        " ".join(uniq(defines)),
    )

    return unhandled_opts

def _process_compiler_opts(
        *,
        conlyopts,
        cxxopts,
        swiftcopts,
        package_bin_dir,
        build_settings):
    """Processes compiler options.

    Args:
        conlyopts: A `list` of C compiler options.
        cxxopts: A `list` of C++ compiler options.
        swiftcopts: A `list` of Swift compiler options.
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
    conlyopts, cxxopts, search_paths = _process_copts(
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        build_settings = build_settings,
    )
    swiftcopts = _process_swiftcopts(
        swiftcopts,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    # TODO: Split out `WARNING_CFLAGS`? (Must maintain order, and only ones that apply to both c and cxx)
    # TODO: Split out `GCC_PREPROCESSOR_DEFINITIONS`? (Must maintain order, and only ones that apply to both c and cxx)
    # TODO: Handle `defines` and `local_defines` as well

    set_if_true(
        build_settings,
        "OTHER_CFLAGS",
        conlyopts,
    )
    set_if_true(
        build_settings,
        "OTHER_CPLUSPLUSFLAGS",
        cxxopts,
    )
    set_if_true(
        build_settings,
        "OTHER_SWIFT_FLAGS",
        " ".join(swiftcopts),
    )

    return search_paths

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
    conlyopts, cxxopts, swiftcopts = _get_unprocessed_compiler_opts(
        ctx = ctx,
        target = target,
    )
    return _process_compiler_opts(
        conlyopts = conlyopts,
        cxxopts = cxxopts,
        swiftcopts = swiftcopts,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

# Linker option parsing

def _process_linker_opts(*, linkopts, build_settings):
    """Processes linker options.

    Args:
        linkopts: A `list` of linker options.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `linkopts`.
    """
    set_if_true(
        build_settings,
        "OTHER_LDFLAGS",
        linkopts,
    )

def _process_target_linker_opts(*, ctx, build_settings):
    """Processes the linker options for a target.

    Args:
        ctx: The aspect context.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from the target's linker options.
    """
    rule_linkopts = getattr(ctx.rule.attr, "linkopts", [])
    rule_linkopts = _expand_make_variables(
        ctx = ctx,
        values = rule_linkopts,
        attribute_name = "linkopts",
    )

    _process_linker_opts(
        linkopts = ctx.fragments.cpp.linkopts + rule_linkopts,
        build_settings = build_settings,
    )

# Utility

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
    """Processes the compiler and linker options for a target.

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
    _process_target_linker_opts(
        ctx = ctx,
        build_settings = build_settings,
    )
    return search_paths

# These functions are exposed only for access in unit tests.
testable = struct(
    process_compiler_opts = _process_compiler_opts,
    process_linker_opts = _process_linker_opts,
)
