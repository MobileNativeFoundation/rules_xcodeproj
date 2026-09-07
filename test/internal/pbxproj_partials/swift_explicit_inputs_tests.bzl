"""Exact manifest generation inputs and separate native preparation contract."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:mock_actions.bzl", "mock_actions")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:compiler_args.bzl", "compiler_args")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:pbxproj_partials.bzl", "pbxproj_partials")

def _swift_explicit_inputs_test_impl(ctx):
    env = unittest.begin(ctx)
    manifest = ctx.actions.declare_file("control.swift-explicit-module-map.json")
    ctx.actions.write(manifest, "[]")
    module = ctx.actions.declare_file("LocalSwift.swiftmodule")
    own_module = ctx.actions.declare_file("Control.swiftmodule")
    pcm = ctx.actions.declare_file("LocalClang.pcm")
    module_map = ctx.actions.declare_file("local/module.modulemap")
    header = ctx.actions.declare_file("local/Header.h")
    source = ctx.actions.declare_file("Generated.swift")

    # If generation ever depends on these, a real generator action cannot pass.
    ctx.actions.run_shell(outputs = [module, own_module, pcm, module_map, header, source], command = "exit 1")
    inventory = struct(direct_sources = (source,), module_maps = (module_map,), swiftmodules = (module,))
    local_swift = struct(swift = struct(swiftmodule = module), clang = None)
    local_clang = struct(swift = None, clang = struct(module_map = module_map, compilation_context = struct(headers = depset([header]))))
    selected = struct(swift = struct(swiftmodule = own_module), clang = None, compilation_context = inventory)
    info = struct(direct_modules = [selected], transitive_modules = depset([local_swift, local_clang, selected]))
    action = struct(
        argv = ["swift_worker", "swiftc", "-Xfrontend", "-explicit-swift-module-map-file", "-Xfrontend", manifest.path],
        inputs = depset([manifest, module, pcm]),
        outputs = depset([own_module]),
    )
    preview = compiler_args.swift_preview_inputs(action, info)
    asserts.equals(env, (manifest,), preview.manifests)

    # Library merge metadata embeds this contract in a depset element.
    asserts.equals(env, [preview], depset([preview]).to_list())
    asserts.equals(env, sorted([module.path, module_map.path]), sorted(preview.paths))
    asserts.equals(env, sorted([module.path, module_map.path, header.path, source.path]), sorted([f.path for f in preview.files.to_list()]))
    implicit = compiler_args.swift_preview_inputs(
        struct(argv = [], inputs = action.inputs, outputs = action.outputs),
        info,
    )
    asserts.equals(env, (), implicit.manifests)
    asserts.equals(env, preview.files.to_list(), implicit.files.to_list())
    for generate in [False, True]:
        actions = mock_actions.create()
        pbxproj_partials.write_target_build_settings(
            actions = actions.mock,
            allow_remote = False,
            apple_generate_dsym = False,
            colorize = False,
            conly_args = [],
            cxx_args = [],
            generate_build_settings = generate,
            generate_swift_debug_settings = True,
            name = "Control",
            separate_index_build_output_base = False,
            swift_args = [],
            swift_preview_inputs = preview,
            tool = None,
        )
        asserts.equals(env, [manifest] if generate else [], actions.run_args["inputs"].to_list())
    unowned = compiler_args.swift_preview_inputs(struct(argv = action.argv, inputs = depset([pcm]), outputs = action.outputs), info)
    asserts.equals(env, (), unowned.manifests)
    asserts.equals(env, [unowned], depset([unowned]).to_list())

    # Implicit-module builds need the same cold local import closure. Only the
    # inexpensive manifest is restricted to the generating action's inventory.
    asserts.equals(env, preview.files.to_list(), unowned.files.to_list())
    cc_inputs = compiler_args.cc_preview_inputs(
        [struct(mnemonic = "CppCompile", inputs = depset([source, own_module, pcm]))],
        {source.path: None},
        struct(headers = depset([header])),
    )
    asserts.equals(env, sorted([source.path, header.path]), sorted([f.path for f in cc_inputs.to_list()]))
    asserts.false(env, own_module in cc_inputs.to_list())
    asserts.false(env, pcm in cc_inputs.to_list())
    return unittest.end(env)

swift_explicit_inputs_test = unittest.make(_swift_explicit_inputs_test_impl)

_CollectedManifestInfo = provider("Manifests collected from a real param-file action.", fields = ["manifests"])

def _param_file_producer_impl(ctx):
    manifest = ctx.actions.declare_file(ctx.label.name + ".swift-explicit-module-map.json")
    ctx.actions.write(manifest, "[]")
    pcm = ctx.actions.declare_file(ctx.label.name + ".pcm")
    ctx.actions.run_shell(outputs = [pcm], command = "exit 1")
    output = ctx.actions.declare_file(ctx.label.name + ".swiftmodule")
    args = ctx.actions.args()
    args.add_all(["-Xfrontend", "-explicit-swift-module-map-file", "-Xfrontend", manifest.path])
    args.use_param_file("@%s", use_always = True)
    ctx.actions.run(executable = "/usr/bin/false", mnemonic = "SwiftCompile", inputs = [manifest, pcm], outputs = [output], arguments = [args])
    return [DefaultInfo(files = depset([output]))]

swift_param_file_producer = rule(implementation = _param_file_producer_impl)

def _collect_manifest_aspect_impl(target, _ctx):
    args = compiler_args.collect(c_sources = {}, cxx_sources = {}, target = target)
    return [_CollectedManifestInfo(manifests = args.swift_preview_inputs.manifests)]

_collect_manifest_aspect = aspect(implementation = _collect_manifest_aspect_impl)

def _swift_param_file_manifest_test_impl(ctx):
    env = unittest.begin(ctx)
    manifests = ctx.attr.producer[_CollectedManifestInfo].manifests
    asserts.equals(env, ["swift_param_file_producer.swift-explicit-module-map.json"], [f.basename for f in manifests])
    return unittest.end(env)

swift_param_file_manifest_test = unittest.make(
    _swift_param_file_manifest_test_impl,
    attrs = {"producer": attr.label(aspects = [_collect_manifest_aspect])},
)
