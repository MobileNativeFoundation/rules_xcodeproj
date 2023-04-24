"""Functions for processing compiler and linker options."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")
load(":files.bzl", "is_relative_path")
load(":input_files.bzl", "CXX_EXTENSIONS", "C_EXTENSIONS")

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

# Compiler option processing

_CC_COMPILE_ACTIONS = {
    "CppCompile": None,
    "ObjcCompile": None,
}

def _is_c_file(filename):
    last_dot_in_basename = filename.rfind(".")
    if last_dot_in_basename <= 0:
        return False
    ext_distance_from_end = len(filename) - last_dot_in_basename - 1
    return filename[-ext_distance_from_end:] in C_EXTENSIONS

def _is_cxx_file(filename):
    last_dot_in_basename = filename.rfind(".")
    if last_dot_in_basename <= 0:
        return False
    ext_distance_from_end = len(filename) - last_dot_in_basename - 1
    return filename[-ext_distance_from_end:] in CXX_EXTENSIONS

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

def _legacy_get_unprocessed_cc_compiler_opts(
        *,
        ctx,
        has_c_sources,
        has_cxx_sources,
        has_swift_opts,
        target,
        implementation_compilation_context):
    if (has_swift_opts or
        not implementation_compilation_context or
        not (has_c_sources or has_cxx_sources)):
        return ([], [], [], [])

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
        args = ctx.actions.args()
        args.add("wrapped_clang")
        args.add_all(conlyopts)
        conly_args = [args]
    else:
        conlyopts = []
        conly_args = []

    if has_cxx_sources:
        base_cxxopts = cc_common.get_memory_inefficient_command_line(
            feature_configuration = feature_configuration,
            action_name = "objc++-compile" if is_objc else "c++-compile",
            variables = variables,
        )
        cxxopts = base_cxxopts + cpp.copts + cpp.cxxopts
        args = ctx.actions.args()
        args.add("wrapped_clang_pp")
        args.add_all(cxxopts)
        cxx_args = [args]
    else:
        cxxopts = []
        cxx_args = []

    return conlyopts, conly_args, cxxopts, cxx_args

def _modern_get_unprocessed_cc_compiler_opts(
        *,
        # buildifier: disable=unused-variable
        ctx,
        has_c_sources,
        has_cxx_sources,
        # buildifier: disable=unused-variable
        has_swift_opts,
        target,
        # buildifier: disable=unused-variable
        implementation_compilation_context):
    conlyopts = []
    conly_args = []
    if has_c_sources:
        for action in target.actions:
            if action.mnemonic not in _CC_COMPILE_ACTIONS:
                continue

            previous_arg = None
            is_c = False
            for arg in action.argv:
                if previous_arg == "-c":
                    is_c = _is_c_file(arg)
                    break
                previous_arg = arg

            if not is_c:
                continue

            # First argument is "wrapped_clang"
            conlyopts = action.argv[1:]
            conly_args = action.args
            break

    cxxopts = []
    cxx_args = []
    if has_cxx_sources:
        for action in target.actions:
            if action.mnemonic not in _CC_COMPILE_ACTIONS:
                continue

            previous_arg = None
            is_cxx = False
            for arg in action.argv:
                if previous_arg == "-c":
                    is_cxx = _is_cxx_file(arg)
                    break
                previous_arg = arg

            if not is_cxx:
                continue

            # First argument is "wrapped_clang_pp"
            cxxopts = action.argv[1:]
            cxx_args = action.args
            break

    return conlyopts, conly_args, cxxopts, cxx_args

# Bazel 6 check
_get_unprocessed_cc_compiler_opts = (
    _modern_get_unprocessed_cc_compiler_opts if hasattr(apple_common, "link_multi_arch_static_library") else _legacy_get_unprocessed_cc_compiler_opts
)

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

    swiftcopts = []
    for action in target.actions:
        if action.mnemonic == "SwiftCompile":
            # First two arguments are "worker" and "swiftc"
            swiftcopts = action.argv[2:]
            break

    conlyopts, conly_args, cxxopts, cxxargs = _get_unprocessed_cc_compiler_opts(
        ctx = ctx,
        has_c_sources = has_c_sources,
        has_cxx_sources = has_cxx_sources,
        has_swift_opts = bool(swiftcopts),
        target = target,
        implementation_compilation_context = implementation_compilation_context,
    )

    if build_mode == "xcode":
        for opt in conlyopts + cxxopts:
            if opt.startswith("-ivfsoverlay`"):
                fail("""\
Using VFS overlays with `build_mode = "xcode"` is unsupported.
""")

    return (
        conlyopts,
        conly_args,
        cxxopts,
        cxxargs,
        swiftcopts,
    )

def _process_cc_opts(opts, *, build_settings):
    """Processes C/C++ compiler options.

    Args:
        opts: A `list` of C/C++ compiler options.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `bool` indicting if the target has debug info enabled.
    """
    has_debug_info = False
    for opt in opts:
        # Short-circuit opts that are too short for our checks
        if len(opt) < 2:
            continue

        if opt == "-g":
            has_debug_info = True
            continue

        if opt[0] != "-":
            continue

        if opt[1] == "D":
            value = opt[2:]
            if value.startswith("OBJC_OLD_DISPATCH_PROTOTYPES"):
                suffix = value[-2:]
                if suffix == "=1":
                    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = False
                elif suffix == "=0":
                    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = True
            continue

    return has_debug_info

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
        A `tuple` containing two elements:

        *   A `bool` indicting if the target has debug info enabled for C.
        *   A `bool` indicting if the target has debug info enabled for C++.
    """
    c_has_debug_info = _process_cc_opts(
        conlyopts,
        build_settings = build_settings,
    )
    cxx_has_debug_info = _process_cc_opts(
        cxxopts,
        build_settings = build_settings,
    )
    return (
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

    clang_opts = []

    def _process_clang_opt(opt, previous_opt, previous_clang_opt):
        if opt == "-Xcc":
            return opt

        is_clang_opt = previous_opt == "-Xcc"

        if opt.startswith("-F"):
            path = opt[2:]
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

    return processed_opts, clang_opts, has_debug_info

def _create_cc_compile_params(
        *,
        actions,
        name,
        args,
        opt_type,
        cc_compiler_params_processor):
    if not args or not actions:
        return None

    def _create_compiler_sub_params(idx, sub_args):
        sub_output = actions.declare_file(
            "{}.rules_xcodeproj.{}.compile.sub-{}.params".format(
                name,
                opt_type,
                idx,
            ),
        )
        actions.write(
            output = sub_output,
            content = sub_args,
        )
        return sub_output

    sub_params = [
        _create_compiler_sub_params(idx, sub_args)
        for idx, sub_args in enumerate(args)
    ]

    params = actions.declare_file(
        "{}.rules_xcodeproj.{}.compile.params".format(
            name,
            opt_type,
        ),
    )

    params_args = actions.args()
    params_args.add(params)
    params_args.add_all(sub_params)

    actions.run(
        executable = cc_compiler_params_processor,
        arguments = [params_args],
        mnemonic = "ProcessCCCompileParams",
        progress_message = "Generating %{output}",
        inputs = sub_params,
        outputs = [params],
    )

    return params

def _create_swift_compile_params(*, actions, name, opts):
    if not opts or not actions:
        return None

    args = actions.args()
    args.add_all(opts)

    output = actions.declare_file(
        "{}.rules_xcodeproj.swift.compile.params".format(name),
    )
    actions.write(
        output = output,
        content = args,
    )
    return output

def _process_compiler_opts(
        *,
        actions,
        name,
        conlyopts,
        conly_args,
        cxxopts,
        cxx_args,
        swiftcopts,
        build_mode,
        cpp_fragment,
        package_bin_dir,
        build_settings,
        cc_compiler_params_processor):
    """Processes compiler options.

    Args:
        actions: `ctx.actions`.
        name: The name of the target.
        conlyopts: A `list` of C compiler options
        conly_args: An `Args` object for C compiler options.
        cxxopts: A `list` of C++ compiler options.
        cxx_args: An `Args` object for C compiler options.
        swiftcopts: A `list` of Swift compiler options.
        build_mode: See `xcodeproj.build_mode`.
        cpp_fragment: The `cpp` configuration fragment.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed the `conlyopts`, `cxxopts`, and
            `swiftcopts` lists.
        cc_compiler_params_processor: The `cc_compiler_params_processor`
            executable.

    Returns:
        A `tuple` containing six elements:

        *   A C compiler params `File`.
        *   A C++ compiler params `File`.
        *   A Swift compiler params `File`.
        *   A `bool` that is `True` if C compiler options contain
            "-D_FORTIFY_SOURCE=1".
        *   A `bool` that is `True` if C++ compiler options contain
            "-D_FORTIFY_SOURCE=1".
        *   A `list` of Swift PCM (clang) compiler options.
    """

    # Xcode's default for `ENABLE_STRICT_OBJC_MSGSEND` doesn't match its new
    # project default, so we need to set it explicitly
    build_settings["ENABLE_STRICT_OBJC_MSGSEND"] = True

    has_swiftcopts = bool(swiftcopts)

    (
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
        swift_has_debug_info,
    ) = _process_swiftcopts(
        opts = swiftcopts,
        build_mode = build_mode,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    if conlyopts or cxxopts or has_swiftcopts:
        if cpp_fragment.apple_generate_dsym:
            build_settings["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
        elif c_has_debug_info or cxx_has_debug_info or swift_has_debug_info:
            # We don't set "DEBUG_INFORMATION_FORMAT" to "dwarf", as we set
            # that at the project level
            pass
        else:
            build_settings["DEBUG_INFORMATION_FORMAT"] = ""

    c_params = _create_cc_compile_params(
        actions = actions,
        name = name,
        args = conly_args,
        opt_type = "c",
        cc_compiler_params_processor = cc_compiler_params_processor,
    )
    cxx_params = _create_cc_compile_params(
        actions = actions,
        name = name,
        args = cxx_args,
        opt_type = "cxx",
        cc_compiler_params_processor = cc_compiler_params_processor,
    )
    swift_params = _create_swift_compile_params(
        actions = actions,
        name = name,
        opts = swiftcopts,
    )

    c_has_fortify_source = "-D_FORTIFY_SOURCE=1" in conlyopts
    cxx_has_fortify_source = "-D_FORTIFY_SOURCE=1" in cxxopts

    return (
        c_params,
        cxx_params,
        swift_params,
        c_has_fortify_source,
        cxx_has_fortify_source,
        clang_opts,
    )

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
        A `tuple` containing six elements:

        *   A C compiler params `File`.
        *   A C++ compiler params `File`.
        *   A Swift compiler params `File`.
        *   A `bool` that is `True` if C compiler options contain
            "-D_FORTIFY_SOURCE=1".
        *   A `bool` that is `True` if C++ compiler options contain
            "-D_FORTIFY_SOURCE=1".
        *   A `list` of Swift PCM (clang) compiler options.
    """
    (
        conlyopts,
        conly_args,
        cxxopts,
        cxx_args,
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
        actions = ctx.actions,
        name = ctx.rule.attr.name,
        conlyopts = conlyopts,
        conly_args = conly_args,
        cxxopts = cxxopts,
        cxx_args = cxx_args,
        swiftcopts = swiftcopts,
        build_mode = build_mode,
        cpp_fragment = ctx.fragments.cpp,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
        cc_compiler_params_processor = (
            ctx.executable._cc_compiler_params_processor
        ),
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
        A `tuple` containing six elements:

        *   A C compiler params `File`.
        *   A C++ compiler params `File`.
        *   A Swift compiler params `File`.
        *   A `bool` that is `True` if C compiler options contain
            "-D_FORTIFY_SOURCE=1".
        *   A `bool` that is `True` if C++ compiler options contain
            "-D_FORTIFY_SOURCE=1".
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
