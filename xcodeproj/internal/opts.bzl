"""Functions for processing compiler and linker options."""

load("//xcodeproj/internal/files:files.bzl", "build_setting_path", "is_relative_path", "quote_if_needed")
load(":collections.bzl", "set_if_true")
load(":memory_efficiency.bzl", "EMPTY_LIST")

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

def _get_unprocessed_cc_compiler_opts(
        *,
        # buildifier: disable=unused-variable
        ctx,
        c_sources,
        cxx_sources,
        # buildifier: disable=unused-variable
        has_swift_opts,
        target,
        # buildifier: disable=unused-variable
        implementation_compilation_context):
    conlyopts = EMPTY_LIST
    conly_args = EMPTY_LIST
    cxxopts = EMPTY_LIST
    cxx_args = EMPTY_LIST

    if not c_sources and not cxx_sources:
        return (conlyopts, conly_args, cxxopts, cxx_args)

    for action in target.actions:
        if action.mnemonic not in _CC_COMPILE_ACTIONS:
            continue

        previous_arg = None
        for arg in action.argv:
            if previous_arg == "-c":
                if not conly_args and arg in c_sources:
                    # First argument is "wrapped_clang"
                    conlyopts = action.argv[1:]
                    conly_args = action.args
                elif not cxx_args and arg in cxx_sources:
                    # First argument is "wrapped_clang_pp"
                    cxxopts = action.argv[1:]
                    cxx_args = action.args
                break
            previous_arg = arg

        if ((not c_sources or conly_args) and
            (not cxx_sources or cxx_args)):
            # We've found all the args we are looking for
            break

    return conlyopts, conly_args, cxxopts, cxx_args

_LOAD_PLUGIN_OPTS = {
    "-load-plugin-executable": None,
    "-load-plugin-library": None,
}

_OVERLAY_OPTS = {
    "-explicit-swift-module-map-file": None,
    "-vfsoverlay": None,
}

def _get_unprocessed_compiler_opts(
        *,
        ctx,
        c_sources,
        cxx_sources,
        target,
        implementation_compilation_context):
    """Returns the unprocessed compiler options for the given target.

    Args:
        ctx: The aspect context.
        c_sources: A `dict` of C source paths.
        cxx_sources: A `dict` of C++ source paths.
        target: The `Target` that the compiler options will be retrieved from.
        implementation_compilation_context: The implementation deps aware
            `CcCompilationContext` for `target`.

    Returns:
        A `tuple` containing three elements:

        *   A `list` of C compiler options.
        *   A `list` of C++ compiler options.
        *   A `list` of Swift compiler options.
    """

    swiftcopts = EMPTY_LIST
    swift_args = EMPTY_LIST
    for action in target.actions:
        if action.mnemonic == "SwiftCompile":
            # First two arguments are "worker" and "swiftc"
            swiftcopts = action.argv[2:]
            swift_args = action.args
            break

    (
        conlyopts,
        conly_args,
        cxxopts,
        cxx_args,
    ) = _get_unprocessed_cc_compiler_opts(
        ctx = ctx,
        c_sources = c_sources,
        cxx_sources = cxx_sources,
        has_swift_opts = bool(swiftcopts),
        target = target,
        implementation_compilation_context = implementation_compilation_context,
    )

    return (
        conlyopts,
        conly_args,
        cxxopts,
        cxx_args,
        swiftcopts,
        swift_args,
    )

_CLANG_SEARCH_PATH_OPTS = {
    "-F": None,
    "-I": None,
    "-iquote": None,
    "-isystem": None,
}

def _process_swiftcopts(
        opts,
        *,
        package_bin_dir,
        build_settings):
    """Processes the full Swift compiler options (including Bazel ones).

    Args:
        opts: A `list` of Swift compiler options.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed from `opts`.

    Returns:
        A `bool` indicting if the target has debug info enabled.
    """
    has_debug_info = False
    next_previous_opt = None
    next_previous_clang_opt = None
    next_previous_frontend_opt = None
    project_set_opts = []
    for opt in opts:
        previous_opt = next_previous_opt
        next_previous_opt = opt

        if opt == "-Xfrontend":
            # Skipped to simplify the checks below
            continue

        previous_frontend_opt = next_previous_frontend_opt
        if previous_opt == "-Xfrontend":
            next_previous_frontend_opt = opt
        else:
            next_previous_frontend_opt = None

        if opt == "-Xcc":
            project_set_opts.append(opt)
            continue

        is_clang_opt = previous_opt == "-Xcc"

        previous_clang_opt = next_previous_clang_opt
        if is_clang_opt:
            next_previous_clang_opt = opt
        else:
            next_previous_clang_opt = None

        if opt == "-g":
            if is_clang_opt:
                project_set_opts.pop()
            else:
                has_debug_info = True
            continue

        compilation_mode = _SWIFT_COMPILATION_MODE_OPTS.get(opt, "")
        if compilation_mode:
            build_settings["SWIFT_COMPILATION_MODE"] = compilation_mode
            continue

        if opt.startswith("-swift-version="):
            version = opt[15:]
            if version != "5.0":
                build_settings["SWIFT_VERSION"] = version
            continue

        if previous_opt == "-emit-objc-header-path":
            if not opt.startswith(package_bin_dir):
                fail("""\
-emit-objc-header-path must be in bin dir of the target. {} is not \
under {}""".format(opt, package_bin_dir))
            header_name = opt[len(package_bin_dir) + 1:]
            build_settings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = header_name
            continue

        if is_clang_opt:
            if opt.startswith("-fmodule-map-file="):
                path = opt[18:]
                absolute_opt = "-fmodule-map-file=" + build_setting_path(path)
                project_set_opts.append(absolute_opt)
                continue

            if (previous_clang_opt in _CLANG_SEARCH_PATH_OPTS):
                absolute_opt = build_setting_path(opt)
                project_set_opts.append(absolute_opt)
                continue

            handled_seach_opt = False
            for search_opt in _CLANG_SEARCH_PATH_OPTS:
                if opt.startswith(search_opt):
                    path = opt[len(search_opt):]
                    if not path:
                        absolute_opt = opt
                    else:
                        project_set_opts.append(search_opt)
                        project_set_opts.append("-Xcc")
                        absolute_opt = build_setting_path(path)
                    project_set_opts.append(absolute_opt)
                    handled_seach_opt = True
                    break
            if handled_seach_opt:
                continue

            # -ivfsoverlay doesn't apply `-working_directory=`, so we need to
            # prefix it ourselves
            if previous_clang_opt == "-ivfsoverlay":
                path = opt
                if is_relative_path(path):
                    absolute_opt = "$(PROJECT_DIR)/" + path
                else:
                    absolute_opt = opt
                project_set_opts.append(absolute_opt)
                continue

            if opt.startswith("-ivfsoverlay"):
                path = opt[12:]
                if path.startswith("="):
                    path = path[1:]
                if not path:
                    absolute_opt = opt
                elif is_relative_path(path):
                    absolute_opt = (
                        "-ivfsoverlay$(PROJECT_DIR)/" + path
                    )
                else:
                    absolute_opt = opt
                project_set_opts.append(absolute_opt)
                continue

            project_set_opts.append(opt)
            continue
        else:
            if previous_opt == "-I":
                path = opt

                # We include non-relative paths in BwX mode to account for
                # `/Applications/Xcode.app/Contents/Developer/Platforms/PLATFORM/Developer/usr/lib`
                absolute_opt = build_setting_path(opt)
                project_set_opts.append(previous_opt)
                project_set_opts.append(absolute_opt)
                continue

            if opt.startswith("-I"):
                path = opt[2:]

                # We include non-relative paths in BwX mode to account for
                # `/Applications/Xcode.app/Contents/Developer/Platforms/PLATFORM/Developer/usr/lib`
                if not path:
                    # We will add the opt back above
                    continue
                absolute_opt = "-I" + build_setting_path(path)
                project_set_opts.append(absolute_opt)
                continue

            if previous_opt == "-F":
                path = opt
                absolute_opt = build_setting_path(opt)
                project_set_opts.append(absolute_opt)
                continue

            if opt.startswith("-F"):
                path = opt[2:]
                if not path:
                    absolute_opt = opt
                else:
                    absolute_opt = "-F" + build_setting_path(path)
                project_set_opts.append(absolute_opt)
                continue

        if previous_opt == "-Xfrontend":
            previous_opt_to_check = previous_frontend_opt
            append_previous_opt = True
        else:
            previous_opt_to_check = previous_opt
            append_previous_opt = False

        if previous_opt_to_check in _OVERLAY_OPTS:
            path = opt
            absolute_opt = build_setting_path(path)
            if append_previous_opt:
                project_set_opts.append(previous_opt)
            project_set_opts.append(absolute_opt)
            continue

        if opt == "-explicit-swift-module-map-file":
            if append_previous_opt:
                project_set_opts.append(previous_opt)
            project_set_opts.append(opt)
            continue

        if opt in _LOAD_PLUGIN_OPTS:
            if append_previous_opt:
                project_set_opts.append(previous_opt)
            project_set_opts.append(opt)
            continue

        if previous_opt_to_check in _LOAD_PLUGIN_OPTS:
            path = opt
            absolute_opt = build_setting_path(path)
            if append_previous_opt:
                project_set_opts.append(previous_opt)
            project_set_opts.append(absolute_opt)
            continue

        if opt.startswith("-vfsoverlay"):
            path = opt[11:]
            if path.startswith("="):
                path = path[1:]
            if not path:
                absolute_opt = opt
            else:
                absolute_opt = "-vfsoverlay" + build_setting_path(path)
            if append_previous_opt:
                project_set_opts.append(previous_opt)
            project_set_opts.append(absolute_opt)
            continue

    # Xcode's SourceKit `source.request.editor.open.interface` request filters a
    # lot of arguments, and the params file in particular. In order to fix this
    # request we need to include `-I` and `-vfsoverlay` arguments in the
    # `OTHER_SWIFT_FLAGS` build setting. Above we set `project_set_opts` to
    # include those arguments. We also filter these same arguments in
    # `swift_compiler_params_processor.py` to prevent duplication.
    #
    # Since `-working-directory` is also filtered for the request, we ensure
    # that relative paths use `$(PROJECT_DIR)`.
    set_if_true(
        build_settings,
        "OTHER_SWIFT_FLAGS",
        " ".join([quote_if_needed(opt) for opt in project_set_opts]),
    )

    return has_debug_info

def _create_compile_params(
        *,
        actions,
        name,
        args,
        opt_type,
        params_processor):
    if not args or not actions:
        return None, None

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
        "{}.rules_xcodeproj.{}.compile.params".format(name, opt_type.lower()),
    )

    params_args = actions.args()
    params_args.add(params)
    params_args.add_all(sub_params)

    actions.run(
        executable = params_processor,
        arguments = [params_args],
        mnemonic = "Process{}CompileParams".format(opt_type),
        progress_message = "Generating %{output}",
        inputs = sub_params,
        outputs = [params],
    )

    return params, sub_params

def _process_compiler_opts(
        *,
        actions,
        build_settings,
        cc_compiler_params_processor,
        conly_args,
        conlyopts,
        cpp_fragment,
        cxx_args,
        cxxopts,
        name,
        package_bin_dir,
        swift_args,
        swift_compiler_params_processor,
        swiftcopts):
    """Processes compiler options.

    Args:
        actions: `ctx.actions`.
        build_settings: A mutable `dict` that will be updated with build
            settings that are parsed the `conlyopts`, `cxxopts`, and
            `swiftcopts` lists.
        cc_compiler_params_processor: The `cc_compiler_params_processor`
            executable.
        conly_args: An `Args` object for C compiler options.
        conlyopts: A `list` of C compiler options.
        cpp_fragment: The `cpp` configuration fragment.
        cxx_args: An `Args` object for C compiler options.
        cxxopts: A `list` of C++ compiler options.
        name: The name of the target.
        package_bin_dir: The package directory for the target within
            `ctx.bin_dir`.
        swift_args: An `Args` object for Swift compiler options.
        swift_compiler_params_processor: The `swift_compiler_params_processor`
            executable.
        swiftcopts: A `list` of Swift compiler options.

    Returns:
        A `tuple` containing six elements:

        *   A C compiler params `File`.
        *   A C++ compiler params `File`.
        *   A Swift compiler params `File`.
        *   A `list` of Swift compiler sub-params `File`s.
        *   A `bool` that is `True` if C compiler options contain
            "-D_FORTIFY_SOURCE=1".
        *   A `bool` that is `True` if C++ compiler options contain
            "-D_FORTIFY_SOURCE=1".
    """
    has_swiftcopts = bool(swiftcopts)

    c_has_debug_info = "-g" in conlyopts
    cxx_has_debug_info = "-g" in cxxopts
    swift_has_debug_info = _process_swiftcopts(
        opts = swiftcopts,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

    if conlyopts or cxxopts or has_swiftcopts:
        if cpp_fragment.apple_generate_dsym:
            # Set to dwarf, because Bazel will generate the dSYMs
            # We don't set "DEBUG_INFORMATION_FORMAT" to "dwarf", as we set
            # that at the project level
            pass
        elif c_has_debug_info or cxx_has_debug_info or swift_has_debug_info:
            # We don't set "DEBUG_INFORMATION_FORMAT" to "dwarf", as we set that
            # at the project level
            pass
        else:
            build_settings["DEBUG_INFORMATION_FORMAT"] = ""

    c_params, _ = _create_compile_params(
        actions = actions,
        name = name,
        args = conly_args,
        opt_type = "C",
        params_processor = cc_compiler_params_processor,
    )
    cxx_params, _ = _create_compile_params(
        actions = actions,
        name = name,
        args = cxx_args,
        opt_type = "CXX",
        params_processor = cc_compiler_params_processor,
    )
    swift_params, swift_sub_params = _create_compile_params(
        actions = actions,
        name = name,
        args = swift_args,
        opt_type = "Swift",
        params_processor = swift_compiler_params_processor,
    )

    c_has_fortify_source = "-D_FORTIFY_SOURCE=1" in conlyopts
    cxx_has_fortify_source = "-D_FORTIFY_SOURCE=1" in cxxopts

    return (
        c_params,
        cxx_params,
        swift_params,
        swift_sub_params,
        c_has_fortify_source,
        cxx_has_fortify_source,
    )

def _process_target_compiler_opts(
        *,
        ctx,
        c_sources,
        cxx_sources,
        target,
        implementation_compilation_context,
        package_bin_dir,
        build_settings):
    """Processes the compiler options for a target.

    Args:
        ctx: The aspect context.
        c_sources: A `dict` of C source paths.
        cxx_sources: A `dict` of C++ source paths.
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
        swift_args,
    ) = _get_unprocessed_compiler_opts(
        ctx = ctx,
        c_sources = c_sources,
        cxx_sources = cxx_sources,
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
        swift_args = swift_args,
        cpp_fragment = ctx.fragments.cpp,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
        cc_compiler_params_processor = (
            ctx.executable._cc_compiler_params_processor
        ),
        swift_compiler_params_processor = (
            ctx.executable._swift_compiler_params_processor
        ),
    )

# API

def process_opts(
        *,
        ctx,
        c_sources,
        cxx_sources,
        target,
        implementation_compilation_context,
        package_bin_dir,
        build_settings):
    """Processes the compiler options for a target.

    Args:
        ctx: The aspect context.
        c_sources: A `dict` of C source paths.
        cxx_sources: A `dict` of C++ source paths.
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
        c_sources = c_sources,
        cxx_sources = cxx_sources,
        target = target,
        implementation_compilation_context = implementation_compilation_context,
        package_bin_dir = package_bin_dir,
        build_settings = build_settings,
    )

# These functions are exposed only for access in unit tests.
testable = struct(
    process_compiler_opts = _process_compiler_opts,
)
