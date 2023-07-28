"""Module containing functions process compile commands."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "use_cpp_toolchain")
load(
    ":providers.bzl",
    "XcodeProjInfo",
)
load(":xcodeprojinfo.bzl", "create_xcodeprojinfo")
load(":xcodeproj_aspect.bzl", "transitive_infos")

_CC_COMPILE_COMMANDS_SKIP_OPTS = [
    "DEBUG_PREFIX_MAP_PWD=.",
    "--serialize-diagnostics",
    "-MMD",
    "-MF",
    "-o",
]

_SWIFT_COMPILE_COMMANDS_SKIP_OPTS = [
    "-enable-batch-mode",
    "-emit-object",
    "-serialize-diagnostics",
]

def transitive_cargvs(
        *,
        base = [],
        infos):
    transitive_argvs = depset(
        base,
        transitive = [
            info.cargvs
            for info in infos
        ],
    )
    return transitive_argvs

def transitive_swiftargvs(
        *,
        base = [],
        infos):
    transitive_argvs = depset(
        base,
        transitive = [
            info.swiftargvs
            for info in infos
        ],
    )
    return transitive_argvs

def _process_c_argv_for_compile(
        *,
        argv):
    previous_arg = None
    process_argv = []
    src = None
    for i in range(len(argv)):
        arg = argv[i]
        if previous_arg == "-c":
            src = arg
        previous_arg = arg
        if " " in arg:
            process_argv.append('"' + arg + '"')
        else:
            process_argv.append(arg)

    return " ".join(process_argv), src

def _process_swift_argv_for_compile(
        *,
        argv):
    process_argv = []
    srcs = []
    for i in range(len(argv)):
        arg = argv[i]
        if arg.endswith(".swift"):
            srcs.append(arg)
        if " " in arg:
            process_argv.append('"' + arg + '"')
        else:
            process_argv.append(arg)
    swift_commands = []
    for src in srcs:
        swift_commands.append((" ".join(process_argv), src))
    return swift_commands

def _process_c_argv_for_index(
        *,
        argv):
    previous_arg = None
    process_argv = []
    src = None
    for i in range(len(argv)):
        arg = argv[i]
        if previous_arg == "-c":
            src = arg
        elif previous_arg == "-o":
            previous_arg = arg
            continue
        previous_arg = arg
        if arg in _CC_COMPILE_COMMANDS_SKIP_OPTS:
            continue
        if " " in arg:
            process_argv.append('"' + arg + '"')
        else:
            process_argv.append(arg)

    return " ".join(process_argv), src

def _process_swift_argv_for_index(
        *,
        argv):
    process_argv = []
    srcs = []
    for i in range(len(argv)):
        arg = argv[i]
        if arg.endswith(".swift"):
            srcs.append(arg)
        elif arg in _SWIFT_COMPILE_COMMANDS_SKIP_OPTS:
            continue
        if " " in arg:
            process_argv.append('"' + arg + '"')
        else:
            process_argv.append(arg)
    swift_commands = []
    for src in srcs:
        swift_commands.append((" ".join(process_argv), src))
    return swift_commands

def post_process_compile_commands(
        *,
        cargvs,
        swiftargvs,
        workspace_directory):
    process_compile_commands = []
    for item in cargvs:
        args, file = _process_c_argv_for_compile(argv = item.argv)
        process_compile_commands.append(struct(
            command = args,
            file = file,
            dirctory = workspace_directory,
        ))
    for item in swiftargvs:
        swift_commands = _process_swift_argv_for_compile(argv = item.argv)
        for args, file in swift_commands:
            process_compile_commands.append(struct(
                command = args,
                file = file,
                dirctory = workspace_directory,
            ))
    return process_compile_commands

def post_process_index_compile_commands(
        *,
        cargvs,
        swiftargvs,
        workspace_directory):
    process_compile_commands = []
    for item in cargvs:
        args, file = _process_c_argv_for_index(argv = item.argv)
        process_compile_commands.append(struct(
            command = args,
            file = file,
            dirctory = workspace_directory,
        ))
    for item in swiftargvs:
        swift_commands = _process_swift_argv_for_index(argv = item.argv)
        for args, file in swift_commands:
            process_compile_commands.append(struct(
                command = args,
                file = file,
                dirctory = workspace_directory,
            ))
    return process_compile_commands

def write_compile_commands_json(
        *,
        ctx,
        compile_commands,
        file_name = "compile_commands.json"):
    actions = ctx.actions
    compile_commands_json = actions.declare_file(file_name)
    actions.write(
        content = json.encode(compile_commands),
        output = compile_commands_json,
    )

    return compile_commands_json

def create_compile_commands_json_symlink(
        *,
        ctx,
        compile_commands_json):
    actions = ctx.actions

    compile_commands_json_symlink = actions.declare_file("compile_commands.json")
    actions.symlink(output = compile_commands_json_symlink, target_file = compile_commands_json)

    return compile_commands_json_symlink

def _xcodeproj_ccdb_aspect_impl(target, ctx):
    providers = []

    if XcodeProjInfo not in target:
        # Only create an `XcodeProjInfo` if the target hasn't already created
        # one
        attrs = dir(ctx.rule.attr)
        info = create_xcodeprojinfo(
            ctx = ctx,
            build_mode = "bazel",
            target = target,
            attrs = attrs,
            transitive_infos = transitive_infos(
                ctx = ctx,
                attrs = attrs,
            ),
        )
        if info:
            providers.append(info)
    
    if "COMPILE_COMMANDS_HOST_TAEGET" in ctx.var:
        host_target_label = Label(ctx.var["COMPILE_COMMANDS_HOST_TAEGET"])
        if host_target_label.package == target.label.package and host_target_label.name == target.label.name:
            cargvs = transitive_cargvs(infos = providers).to_list()
            swiftargvs = transitive_swiftargvs(infos = providers).to_list()
            workspace_directory = "__EXEC_ROOT__"
            if "COMPILE_COMMANDS_CWD" in ctx.var:
                workspace_directory = ctx.var["COMPILE_COMMANDS_CWD"]
            if ctx.attr._build_mode == "alldb":
                process_compile_commands = post_process_compile_commands(
                    cargvs = cargvs,
                    swiftargvs = swiftargvs,
                    workspace_directory = workspace_directory,
                )
                process_index_compile_commands = post_process_index_compile_commands(
                    cargvs = cargvs,
                    swiftargvs = swiftargvs,
                    workspace_directory = workspace_directory,
                )
                compile_commands_json = write_compile_commands_json(
                    ctx = ctx,
                    compile_commands = process_compile_commands,
                )
                index_compile_commands_json = write_compile_commands_json(
                    ctx = ctx,
                    compile_commands = process_index_compile_commands,
                    file_name = "index_compile_commands.json",
                )
                providers.append(OutputGroupInfo(compile_commands = [compile_commands_json, index_compile_commands_json]))
            elif ctx.attr._build_mode == "indexdb":
                process_compile_commands = post_process_index_compile_commands(
                    cargvs = cargvs,
                    swiftargvs = swiftargvs,
                    workspace_directory = workspace_directory,
                )
                compile_commands_json = write_compile_commands_json(
                    ctx = ctx,
                    compile_commands = process_compile_commands,
                )
                providers.append(OutputGroupInfo(compile_commands = [compile_commands_json]))
            else:
                process_compile_commands = post_process_compile_commands(
                    cargvs = cargvs,
                    swiftargvs = swiftargvs,
                    workspace_directory = workspace_directory,
                )
                compile_commands_json = write_compile_commands_json(
                    ctx = ctx,
                    compile_commands = process_compile_commands,
                )
                providers.append(OutputGroupInfo(compile_commands = [compile_commands_json]))

    return providers

def _make_xcodeproj_ccdb_aspect(*, build_mode, generator_name):
    return aspect(
        implementation = _xcodeproj_ccdb_aspect_impl,
        attr_aspects = ["*"],
        attrs = {
            "_build_mode": attr.string(default = build_mode),
            "_cc_compiler_params_processor": attr.label(
                cfg = "exec",
                default = Label(
                    "//tools/params_processors:cc_compiler_params_processor",
                ),
                executable = True,
            ),
            "_cc_toolchain": attr.label(default = Label(
                "@bazel_tools//tools/cpp:current_cc_toolchain",
            )),
            "_generator_name": attr.string(default = generator_name),
            "_swift_compiler_params_processor": attr.label(
                cfg = "exec",
                default = Label(
                    "//tools/params_processors:swift_compiler_params_processor",
                ),
                executable = True,
            ),
            "_xcode_config": attr.label(
                default = configuration_field(
                    name = "xcode_config_label",
                    fragment = "apple",
                ),
            ),
        },
        fragments = ["apple", "cpp", "objc"],
        toolchains = use_cpp_toolchain(),
    )

# FIXME: setup a valid generator_name
compile_commands_aspect = _make_xcodeproj_ccdb_aspect(build_mode = "compiledb", generator_name="generator_name")
index_commands_aspect = _make_xcodeproj_ccdb_aspect(build_mode = "indexdb", generator_name="generator_name")
all_commands_aspect = _make_xcodeproj_ccdb_aspect(build_mode = "alldb", generator_name="generator_name")
