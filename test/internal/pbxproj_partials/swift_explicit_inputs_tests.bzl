"""Declared Swift and Clang inputs are prepared for native Index Build."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:compiler_args.bzl", "compiler_args")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal/files:output_files.bzl", "output_files", "output_groups")

def _swift_explicit_inputs_test_impl(ctx):
    env = unittest.begin(ctx)
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
        argv = ["swift_worker", "swiftc"],
        inputs = depset([module, pcm]),
        outputs = depset([own_module]),
    )
    preview = compiler_args.swift_preview_inputs(action, info)

    # Library merge metadata embeds this contract in a depset element.
    asserts.equals(env, [preview], depset([preview]).to_list())
    asserts.equals(env, sorted([module.path, module_map.path, header.path, source.path]), sorted([f.path for f in preview.files.to_list()]))

    _, _, output_metadata = output_files.collect(
        actions = ctx.actions,
        compile_params_files = [],
        debug_outputs = None,
        id = "INDEX_TARGET",
        name = "IndexTarget",
        output_group_info = None,
        preview_swift_import_files = preview.files,
        product = None,
        swift_info = None,
        transitive_infos = [],
    )
    index_groups = output_groups.collect(metadata = output_metadata, transitive_infos = [])
    groups = output_groups.to_output_groups_fields(target_output_groups = index_groups)
    index_inputs = groups["bi INDEX_TARGET"].to_list()
    for file in [module, module_map, header, source]:
        asserts.true(env, file in index_inputs)

    # A selected mixed wrapper has its own BAZEL_TARGET_ID. Its indexing
    # request cannot rely on the Swift and Clang children's differently named
    # output groups, even when those children have been merged into it.
    _, _, mixed_metadata = output_files.collect_mixed_language(
        actions = ctx.actions,
        compile_params_files = [],
        debug_outputs = None,
        id = "MIXED_INDEX_TARGET",
        indexstore_overrides = [],
        mixed_target_infos = [],
        name = "MixedIndexTarget",
        output_group_info = None,
        preview_swift_import_files = preview.files,
        swift_info = None,
        transitive_infos = [],
    )
    mixed_groups = output_groups.to_output_groups_fields(
        target_output_groups = output_groups.collect(
            metadata = mixed_metadata,
            transitive_infos = [],
        ),
    )
    mixed_inputs = mixed_groups["bi MIXED_INDEX_TARGET"].to_list()
    for file in [module, module_map, header, source]:
        asserts.true(env, file in mixed_inputs)
    asserts.true(env, "MixedIndexTarget-bi.filelist" in [file.basename for file in mixed_inputs])
    implicit = compiler_args.swift_preview_inputs(
        struct(argv = [], inputs = action.inputs, outputs = action.outputs),
        info,
    )
    asserts.equals(env, preview.files.to_list(), implicit.files.to_list())

    # Modern binary XCFramework imports carry Swift and Clang in one context.
    # Being a framework does not change exact direct-context ownership.
    framework = struct(is_framework = True, swift = local_swift.swift, clang = local_clang.clang)
    framework_info = struct(direct_modules = [selected], transitive_modules = depset([framework, selected]))
    framework_preview = compiler_args.swift_preview_inputs(action, framework_info)
    asserts.equals(env, preview.files.to_list(), framework_preview.files.to_list())
    for dependency in [
        struct(is_framework = True, swift = struct(swiftmodule = own_module), clang = None),
        struct(is_framework = True, swift = struct(swiftmodule = pcm), clang = None),
        struct(is_system = True, swift = struct(swiftmodule = own_module), clang = None),
        struct(is_system = True, swift = struct(swiftmodule = pcm), clang = None),
        struct(is_system = True, swift = struct(swiftmodule = "__BAZEL_XCODE_SDKROOT__/usr/lib/swift/Swift.swiftmodule"), clang = None),
    ]:
        excluded = compiler_args.swift_preview_inputs(
            action,
            struct(direct_modules = [selected], transitive_modules = depset([dependency])),
        )
        asserts.equals(env, [source, module], excluded.files.to_list())

    # Private/toolchain Swift modules are not necessarily propagated at all.
    # rules_swift 4.1's generated system modules must come from the exact direct
    # compile context, not a differently configured public dependency.
    direct_only = struct(compilation_context = struct(
        direct_sources = (),
        module_maps = (),
        swiftmodules = (module, own_module, "__BAZEL_XCODE_SDKROOT__/Swift.swiftmodule"),
    ))
    direct_preview = compiler_args.swift_preview_inputs(
        action,
        struct(direct_modules = [direct_only], transitive_modules = depset()),
    )
    asserts.equals(env, [module], direct_preview.files.to_list())

    # Implicit-module builds need the same cold local import closure.
    cc_inputs = compiler_args.cc_preview_inputs(
        [struct(mnemonic = "CppCompile", inputs = depset([source, own_module, pcm]))],
        {source.path: None},
        struct(headers = depset([header])),
    )
    asserts.equals(env, sorted([source.path, header.path]), sorted([f.path for f in cc_inputs.to_list()]))
    asserts.false(env, own_module in cc_inputs.to_list())
    asserts.false(env, pcm in cc_inputs.to_list())

    # Bridging headers may be generated swiftc_inputs, without a Clang module.
    for flags in [["-import-objc-header", header.path], ["-Xfrontend", "-import-objc-header", "-Xfrontend", header.path]]:
        bridging = compiler_args.swift_preview_inputs(
            struct(argv = flags, inputs = depset([header, own_module, pcm]), outputs = depset([own_module])),
            None,
        )
        asserts.equals(env, [header], bridging.files.to_list())
    for path in ["unowned.h", own_module.path]:
        bridging = compiler_args.swift_preview_inputs(
            struct(argv = ["-import-objc-header", path], inputs = depset([own_module]), outputs = depset([own_module])),
            None,
        )
        asserts.equals(env, [], bridging.files.to_list())
    return unittest.end(env)

swift_explicit_inputs_test = unittest.make(_swift_explicit_inputs_test_impl)
