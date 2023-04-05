"""Functions for processing compiler and linker options."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load(":collections.bzl", "uniq")
load(":files.bzl", "is_relative_path")

# C and C++ compiler flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_CC_SKIP_OPTS = {
    # Xcode sets these, and no way to unset them
    "-isysroot": 2,
    "-mios-simulator-version-min": 1,
    "-miphoneos-version-min": 1,
    "-mmacosx-version-min": 1,
    "-mtvos-simulator-version-min": 1,
    "-mtvos-version-min": 1,
    "-mwatchos-simulator-version-min": 1,
    "-mwatchos-version-min": 1,
    "-target": 2,

    # We want Xcode to control coloring
    "-fcolor-diagnostics": 1,
}

# Swift compiler flags that we don't want to propagate to Xcode.
# The values are the number of flags to skip, 1 being the flag itself, 2 being
# another flag right after it, etc.
_SWIFTC_SKIP_OPTS = {
    # Xcode sets output paths
    "-emit-module-path": 2,
    "-emit-object": 1,
    "-output-file-map": 2,

    # Xcode sets these, and no way to unset them
    "-enable-bare-slash-regex": 1,
    "-module-name": 2,
    "-num-threads": 2,
    "-parse-as-library": 1,
    "-sdk": 2,
    "-target": 2,

    # We want to use Xcode's normal PCM handling
    "-module-cache-path": 2,

    # We want Xcode's normal debug handling
    "-debug-prefix-map": 2,
    "-file-prefix-map": 2,
    "-gline-tables-only": 1,

    # We want to use Xcode's normal indexing handling
    "-index-ignore-system-modules": 1,
    "-index-store-path": 2,

    # We set Xcode build settings to control these
    "-enable-batch-mode": 1,

    # We don't want to translate this for BwX
    "-emit-symbol-graph-dir": 2,

    # This is rules_swift specific, and we don't want to translate it for BwX
    "-Xwrapped-swift": 1,
}

_SWIFTC_SKIP_COMPOUND_OPTS = {
    "-Xfrontend": {
        # We want Xcode to control coloring
        "-color-diagnostics": 1,

        # We want Xcode's normal debug handling
        "-no-clang-module-breadcrumbs": 1,
        "-no-serialize-debugging-options": 1,
        "-serialize-debugging-options": 1,

        # We don't want to translate this for BwX
        "-emit-symbol-graph": 1,
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

def _get_unprocessed_compiler_opts(
        *,
        ctx,
        build_mode,
        has_c_sources,
        has_cxx_sources,
        target,
        implementation_compilation_context):
    """Returns the unprocessed compiler options for the given target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        has_c_sources: `True` if `target` has C sources.
        has_cxx_sources: `True` if `target` has C++ sources.
        target: The `Target` that the compiler options will be retrieved from.
        implementation_compilation_context: The implementation deps aware
            `CcCompilationContext` for `target`.

    Returns:
        A `tuple` containing three elements:

        *   A `list` of C compiler options.
        *   A `list` of C++ compiler options.
        *   A `list` of Swift compiler options.
    """

    # TODO: Handle perfileopts somehow?

    swiftcopts = []
    for action in target.actions:
        if action.mnemonic == "SwiftCompile":
            # First two arguments are "worker" and "swiftc"
            swiftcopts = action.argv[2:]

    if (not swiftcopts and implementation_compilation_context and
        (has_c_sources or has_cxx_sources)):
        cc_toolchain = find_cpp_toolchain(ctx)

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

        is_objc = apple_common.Objc in target
        if is_objc:
            objc = ctx.fragments.objc
            user_copts = (
                objc.copts +
                user_copts +
                objc.copts_for_current_compilation_mode
            )

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
            user_compile_flags = user_copts,
            include_directories = implementation_compilation_context.includes,
            quote_include_directories = implementation_compilation_context.quote_includes,
            system_include_directories = implementation_compilation_context.system_includes,
            framework_include_directories = (
                implementation_compilation_context.framework_includes
            ),
            preprocessor_defines = depset(
                transitive = [
                    implementation_compilation_context.local_defines,
                    implementation_compilation_context.defines,
                ],
            ),
        )

        cpp = ctx.fragments.cpp

        if has_c_sources:
            base_copts = cc_common.get_memory_inefficient_command_line(
                feature_configuration = feature_configuration,
                action_name = "objc-compile" if is_objc else "c-compile",
                variables = variables,
            )
            conlyopts = base_copts + cpp.copts + cpp.conlyopts
        else:
            conlyopts = []

        if has_cxx_sources:
            base_cxxopts = cc_common.get_memory_inefficient_command_line(
                feature_configuration = feature_configuration,
                action_name = "objc++-compile" if is_objc else "c++-compile",
                variables = variables,
            )
            cxxopts = base_cxxopts + cpp.copts + cpp.cxxopts
        else:
            cxxopts = []

        if build_mode == "xcode":
            for opt in conlyopts + cxxopts:
                if opt.startswith("-ivfsoverlay`"):
                    fail("""\
Using VFS overlays with `build_mode = "xcode"` is unsupported.
""")
    else:
        conlyopts = []
        cxxopts = []

    return (
        conlyopts,
        cxxopts,
        swiftcopts,
    )

def create_search_paths(*, framework_includes):
    """Creates a value representing search paths of a target.

    Args:
        framework_includes: A `list` of framework include paths (i.e. `-F`
            values).

    Returns:
        A `struct` containing the `framework_includes` fields provided as
        arguments.
    """
    return struct(
        framework_includes = tuple(framework_includes),
    )

def merge_search_paths(search_paths):
    """Merges a `list` of search paths into a single set set of search paths.

    Args:
        search_paths: A `list` of values returned from
            `create_search_paths`.

    Returns:
        A value returned from `create_search_paths`, with the search paths
        provided to it being the merged and deduplicated values from
        `search_paths`.
    """
    framework_includes = []

    for search_path in search_paths:
        framework_includes.extend(search_path.framework_includes)

    return create_search_paths(
        framework_includes = uniq(framework_includes),
    )

def _process_cc_opts(opts, *, build_settings):
    """Processes C/C++ compiler options.

    Args:
        opts: A `list` of C/C++ compiler options.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `tuple` containing five elements:

        *   A `list` of unhandled C/C++ compiler options.
        *   A `list` of C/C++ compiler optimization levels parsed.
        *   A value returned by `create_search_paths` with the parsed search
            paths.
        *   A `bool` indicting if the target has debug info enabled.
    """
    optimizations = []
    framework_includes = []
    has_debug_info = {}

    def _inner_process_cc_opts(opt, previous_opt):
        # Short-circuit opts that are too short for our checks
        if len(opt) < 2:
            return opt

        if previous_opt == "-ivfsoverlay" or previous_opt == "--config":
            if opt[0] != "/":
                return "$(CURRENT_EXECUTION_ROOT)/" + opt
            return opt

        if opt[0] != "-":
            return opt
        opt_character = opt[1]

        if opt_character == "O":
            optimizations.append(opt)
            return None
        if opt == "-F":
            return opt
        if opt_character == "F":
            framework_includes.append(opt[2:])
            return opt
        if opt_character == "D":
            value = opt[2:]
            if value.startswith("OBJC_OLD_DISPATCH_PROTOTYPES"):
                suffix = value[-2:]
                if suffix == "=1":
                    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = False
                elif suffix == "=0":
                    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = True
                return None
            return opt

        # -ivfsoverlay and --config doesn't apply `-working_directory=`, so we
        # need to prefix it ourselves
        if opt.startswith("-ivfsoverlay"):
            value = opt[12:]
            if not value.startswith("/"):
                return "-ivfsoverlay" + "$(CURRENT_EXECUTION_ROOT)/" + value
            return opt

        return opt

    processed_opts = []
    has_debug_info = False
    skip_next = 0
    outer_previous_opt = None
    for outer_opt in opts:
        if skip_next:
            skip_next -= 1
            continue
        root_opt = outer_opt.split("=")[0]

        skip_next = _CC_SKIP_OPTS.get(root_opt, 0)
        if skip_next:
            skip_next -= 1
            continue

        if outer_opt == "-g":
            has_debug_info = True
            continue

        processed_opt = _inner_process_cc_opts(outer_opt, outer_previous_opt)

        outer_previous_opt = outer_opt

        outer_opt = processed_opt
        if not outer_opt:
            continue

        processed_opts.append(outer_opt)

    search_paths = create_search_paths(
        framework_includes = uniq(framework_includes),
    )

    return processed_opts, optimizations, search_paths, has_debug_info

def _process_copts(
        *,
        conlyopts,
        cxxopts,
        build_settings):
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
        *   A value returned by `create_search_paths` with the parsed search
            paths.
        *   A `bool` indicting if the target has debug info enabled for C.
        *   A `bool` indicting if the target has debug info enabled for C++.
    """
    has_copts = conlyopts or cxxopts

    (
        conlyopts,
        conly_optimizations,
        conly_search_paths,
        c_has_debug_info,
    ) = _process_cc_opts(conlyopts, build_settings = build_settings)
    (
        cxxopts,
        cxx_optimizations,
        cxx_search_paths,
        cxx_has_debug_info,
    ) = _process_cc_opts(cxxopts, build_settings = build_settings)

    if has_copts:
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
            conly_optimizations = ([default_conly_optimization] +
                                   conly_optimizations)
            cxx_optimizations = [default_cxx_optimization] + cxx_optimizations
        build_settings["GCC_OPTIMIZATION_LEVEL"] = gcc_optimization[2:]

    return (
        conly_optimizations + conlyopts,
        cxx_optimizations + cxxopts,
        conly_search_paths,
        cxx_search_paths,
        c_has_debug_info,
        cxx_has_debug_info,
    )

_CLANG_SEARCH_PATHS = {
    "-iquote": None,
    "-isystem": None,
    "-I": None,
}

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
        *   A `list` of clang compiler options.
        *   A value returned by `create_search_paths` with the parsed search
            paths.
        *   A `bool` indicting if the target has debug info enabled.
    """

    # Xcode needs a value for SWIFT_VERSION, so we set it to "5.0" by default.
    # We will have to figure out a way to detect what the default is before
    # Swift 6 (which will probably have a new language version).
    build_settings["SWIFT_VERSION"] = "5.0"

    # Default to not creating the Swift generated header.
    build_settings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = ""

    # Xcode's default is `-O` when not set, so minimally set it to `-Onone`,
    # which matches swiftc's default.
    build_settings["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone"

    framework_includes = []
    clang_opts = []

    def _process_clang_opt(opt, previous_opt, previous_clang_opt):
        if opt == "-Xcc":
            return opt

        is_clang_opt = previous_opt == "-Xcc"

        if opt.startswith("-F"):
            path = opt[2:]
            framework_includes.append(path)
            if is_clang_opt:
                if path == ".":
                    clang_opt = "-F$(PROJECT_DIR)"
                elif is_relative_path(path):
                    clang_opt = "-F$(PROJECT_DIR)/" + path
                else:
                    clang_opt = opt
                clang_opts.append(clang_opt)
            return opt

        is_bwx = build_mode == "xcode"
        if not (is_clang_opt or is_bwx):
            return None

        if opt.startswith("-fmodule-map-file="):
            path = opt[18:]
            is_relative = is_relative_path(path)
            if is_clang_opt or is_relative:
                if path == ".":
                    bwx_opt = "-fmodule-map-file=$(PROJECT_DIR)"
                elif is_relative:
                    bwx_opt = "-fmodule-map-file=$(PROJECT_DIR)/" + path
                else:
                    bwx_opt = opt
                if is_bwx:
                    opt = bwx_opt
                clang_opts.append(bwx_opt)
            return opt
        if opt.startswith("-iquote"):
            path = opt[7:]
            if not path:
                if is_clang_opt:
                    clang_opts.append(opt)
                return opt
            is_relative = is_relative_path(path)
            if is_clang_opt or is_relative:
                if path == ".":
                    bwx_opt = "-iquote$(PROJECT_DIR)"
                elif is_relative:
                    bwx_opt = "-iquote$(PROJECT_DIR)/" + path
                else:
                    bwx_opt = opt
                if is_bwx:
                    opt = bwx_opt
                if is_clang_opt:
                    clang_opts.append(bwx_opt)
            return opt
        if opt.startswith("-I"):
            path = opt[2:]
            if not path:
                if is_clang_opt:
                    clang_opts.append(opt)
                return opt
            is_relative = is_relative_path(path)
            if is_clang_opt or is_relative:
                if path == ".":
                    bwx_opt = "-I$(PROJECT_DIR)"
                elif is_relative:
                    bwx_opt = "-I$(PROJECT_DIR)/" + path
                else:
                    bwx_opt = opt
                if is_bwx:
                    opt = bwx_opt
                if is_clang_opt:
                    clang_opts.append(bwx_opt)
            return opt
        if opt.startswith("-isystem"):
            path = opt[8:]
            if not path:
                if is_clang_opt:
                    clang_opts.append(opt)
                return opt
            is_relative = is_relative_path(path)
            if is_clang_opt or is_relative:
                if path == ".":
                    bwx_opt = "-isystem$(PROJECT_DIR)"
                elif is_relative:
                    bwx_opt = "-isystem$(PROJECT_DIR)/" + path
                else:
                    bwx_opt = opt
                if is_bwx:
                    opt = bwx_opt
                if is_clang_opt:
                    clang_opts.append(bwx_opt)
            return opt
        if previous_clang_opt in _CLANG_SEARCH_PATHS:
            if opt == ".":
                opt = "$(PROJECT_DIR)"
            elif is_relative_path(opt):
                opt = "$(PROJECT_DIR)/" + opt
            clang_opts.append(opt)
            return opt
        if is_clang_opt:
            # -vfsoverlay doesn't apply `-working_directory=`, so we need to
            # prefix it ourselves
            if previous_clang_opt == "-ivfsoverlay":
                if opt[0] != "/":
                    opt = "$(CURRENT_EXECUTION_ROOT)/" + opt
            elif opt.startswith("-ivfsoverlay"):
                value = opt[12:]
                if not value.startswith("/"):
                    opt = "-ivfsoverlay$(CURRENT_EXECUTION_ROOT)/" + value

            # We do this check here, to prevent the `-O` logic below
            # from incorrectly detecting this situation
            clang_opts.append(opt)
            return opt

        return None

    def _inner_process_swiftcopts(opt, previous_opt, previous_frontend_opt, previous_clang_opt):
        clang_opt = _process_clang_opt(opt, previous_opt, previous_clang_opt)
        if clang_opt:
            return clang_opt

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
        if opt == "-enable-testing":
            build_settings["ENABLE_TESTABILITY"] = True
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
        if opt[0] != "-" and opt.endswith(".swift"):
            # These are the files to compile, not options. They are seen here
            # because of the way we collect Swift compiler options. Ideally in
            # the future we could collect Swift compiler options similar to how
            # we collect C and C++ compiler options.
            return None

        if opt == "-Xfrontend":
            # We return early to prevent issues with the checks below
            return opt

        # -vfsoverlay doesn't apply `-working_directory=`, so we need to
        # prefix it ourselves
        previous_vfsoverlay_opt = previous_frontend_opt or previous_opt
        if previous_vfsoverlay_opt == "-vfsoverlay":
            if opt[0] != "/":
                return "$(CURRENT_EXECUTION_ROOT)/" + opt
            return opt
        if opt.startswith("-vfsoverlay"):
            value = opt[11:]
            if value and value[0] != "/":
                return "-vfsoverlay$(CURRENT_EXECUTION_ROOT)/" + value
            return opt

        return opt

    processed_opts = []
    has_debug_info = False
    skip_next = 0
    outer_previous_opt = None
    outer_previous_frontend_opt = None
    outer_previous_clang_opt = None
    for idx, outer_opt in enumerate(opts):
        if skip_next:
            skip_next -= 1
            continue
        root_opt = outer_opt.split("=")[0]

        skip_next = _SWIFTC_SKIP_OPTS.get(root_opt, 0)
        if skip_next:
            skip_next -= 1
            continue

        compound_skip_next = _SWIFTC_SKIP_COMPOUND_OPTS.get(root_opt)
        if compound_skip_next:
            skip_next = compound_skip_next.get(opts[idx + 1], 0)
            if skip_next:
                # No need to decrement 1, since we need to skip the first opt
                continue

        if outer_opt == "-g":
            has_debug_info = True
            continue

        processed_opt = _inner_process_swiftcopts(
            outer_opt,
            outer_previous_opt,
            outer_previous_frontend_opt,
            outer_previous_clang_opt,
        )

        if outer_previous_opt == "-Xcc":
            outer_previous_clang_opt = outer_opt
            outer_previous_frontend_opt = None
        elif outer_opt != "-Xcc":
            outer_previous_clang_opt = None
            if outer_previous_opt == "-Xfrontend":
                outer_previous_frontend_opt = outer_opt
            elif outer_opt != "-Xfrontend":
                outer_previous_frontend_opt = None
        outer_previous_opt = outer_opt

        outer_opt = processed_opt
        if not outer_opt:
            continue

        processed_opts.append(outer_opt)

    search_paths = create_search_paths(
        framework_includes = uniq(framework_includes),
    )

    return processed_opts, clang_opts, search_paths, has_debug_info

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
        A `tuple` containing five elements:

        *   A value returned by `create_search_paths` with the parsed search
            paths.
        *   A `list` of C compiler options.
        *   A `list` of C++ compiler options.
        *   A `list` of Swift compiler options.
        *   A `list` of Swift PCM (clang) compiler options.
    """

    # Xcode's default for `ENABLE_STRICT_OBJC_MSGSEND` doesn't match its new
    # project default, so we need to set it explicitly
    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = True

    has_conlyopts = conlyopts
    has_cxxopts = cxxopts
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
    (
        swiftcopts,
        clang_opts,
        swift_search_paths,
        swift_has_debug_info,
    ) = _process_swiftcopts(
        opts = swiftcopts,
        build_mode = build_mode,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    has_debug_info = {}
    if has_conlyopts:
        has_debug_info[c_has_debug_info] = None
    if has_cxxopts:
        has_debug_info[cxx_has_debug_info] = None
    if has_swiftcop:
        has_debug_info[swift_has_debug_info] = None

    has_debug_infos = has_debug_info.keys()

    if len(has_debug_infos) == 1:
        # We don't set "DEBUG_INFORMATION_FORMAT" for "dwarf", as we set that at
        # the project level.
        if not has_debug_infos[0]:
            build_settings["DEBUG_INFORMATION_FORMAT"] = ""
        elif cpp_fragment.apple_generate_dsym:
            build_settings["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
    elif has_debug_infos:
        build_settings["DEBUG_INFORMATION_FORMAT"] = ""
        if has_conlyopts and c_has_debug_info:
            conlyopts = ["-g"] + conlyopts
        if has_cxxopts and cxx_has_debug_info:
            cxxopts = ["-g"] + cxxopts
        if has_swiftcop and swift_has_debug_info:
            swiftcopts = ["-g"] + swiftcopts

    search_paths = merge_search_paths([
        conly_search_paths,
        cxx_search_paths,
        swift_search_paths,
    ])

    return search_paths, conlyopts, cxxopts, swiftcopts, clang_opts

def _process_target_compiler_opts(
        *,
        ctx,
        build_mode,
        has_c_sources,
        has_cxx_sources,
        target,
        implementation_compilation_context,
        package_bin_dir,
        build_settings):
    """Processes the compiler options for a target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        has_c_sources: `True` if `target` has C sources.
        has_cxx_sources: `True` if `target` has C++ sources.
        target: The `Target` that the compiler options will be retrieved from.
        implementation_compilation_context: The implementation deps aware
            `CcCompilationContext` for `target`.
        package_bin_dir: The package directory for `target` within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from the target's compiler options.

    Returns:
        A `tuple` containing five elements:

        *   A value returned by `create_search_paths` with the parsed search
            paths.
        *   A `list` of C compiler options.
        *   A `list` of C++ compiler options.
        *   A `list` of Swift compiler options.
        *   A `list` of Swift PCM (clang) compiler options.
    """
    (
        conlyopts,
        cxxopts,
        swiftcopts,
    ) = _get_unprocessed_compiler_opts(
        ctx = ctx,
        build_mode = build_mode,
        has_c_sources = has_c_sources,
        has_cxx_sources = has_cxx_sources,
        target = target,
        implementation_compilation_context = implementation_compilation_context,
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
        ctx.expand_make_variables(attribute_name, token, {})
        for value in values
        # TODO: Handle `no_copts_tokenization`
        for token in ctx.tokenize(value)
    ]

# API

def process_opts(
        *,
        ctx,
        build_mode,
        has_c_sources,
        has_cxx_sources,
        target,
        implementation_compilation_context,
        package_bin_dir,
        build_settings):
    """Processes the compiler options for a target.

    Args:
        ctx: The aspect context.
        build_mode: See `xcodeproj.build_mode`.
        has_c_sources: `True` if `target` has C sources.
        has_cxx_sources: `True` if `target` has C++ sources.
        target: The `Target` that the compiler and linker options will be
            retrieved from.
        implementation_compilation_context: The implementation deps aware
            `CcCompilationContext` for `target`.
        package_bin_dir: The package directory for `target` within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from the compiler and linker options.

    Returns:
        A `tuple` containing two elements:

        *   A value returned by `create_search_paths` with the parsed search
            paths.
        *   A `list` of C compiler options.
        *   A `list` of C++ compiler options.
        *   A `list` of Swift compiler options.
        *   A `list` of Swift PCM (clang) compiler options.
    """
    return _process_target_compiler_opts(
        ctx = ctx,
        build_mode = build_mode,
        has_c_sources = has_c_sources,
        has_cxx_sources = has_cxx_sources,
        target = target,
        implementation_compilation_context = implementation_compilation_context,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

# These functions are exposed only for access in unit tests.
testable = struct(
    process_compiler_opts = _process_compiler_opts,
)
