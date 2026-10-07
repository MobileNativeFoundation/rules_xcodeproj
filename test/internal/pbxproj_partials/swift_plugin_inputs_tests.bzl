"""Cold native compilation prepares only executable plugins owned by its action."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:compiler_args.bzl", "compiler_args")

def _swift_plugin_inputs_test_impl(ctx):
    env = unittest.begin(ctx)
    plugin = ctx.actions.declare_file("macro_plugin")
    unrelated = ctx.actions.declare_file("unrelated_executable")
    own_output = ctx.actions.declare_file("selected_output")
    ctx.actions.run_shell(outputs = [plugin, unrelated, own_output], command = "exit 1")
    argv = ["-Xfrontend", "-load-plugin-executable", "-Xfrontend", plugin.path + "#First,Second"]
    action = struct(argv = argv, inputs = depset([plugin, unrelated]), outputs = depset([own_output]))
    prepared = compiler_args.swift_preview_inputs(action, None)
    asserts.equals(env, [plugin], prepared.files.to_list())

    # Flag-shaped strings do not authorize missing/unrelated inputs, outputs,
    # SDK plugin search directories, or incomplete options.
    for inputs, outputs, flags in [
        ([], [], argv),
        ([plugin], [plugin], argv),
        ([plugin], [], ["-Xfrontend", "-load-plugin-executable", "-Xfrontend"]),
        ([plugin], [], ["-plugin-path", plugin.path]),
        ([plugin], [], []),
    ]:
        empty = compiler_args.swift_preview_inputs(struct(argv = flags, inputs = depset(inputs), outputs = depset(outputs)), None)
        asserts.equals(env, [], empty.files.to_list())
    return unittest.end(env)

swift_plugin_inputs_test = unittest.make(_swift_plugin_inputs_test_impl)
