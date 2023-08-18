""" Functions for processing non-Xcode targets """

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
    "AppleResourceInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":configuration.bzl", "calculate_configuration")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":memory_efficiency.bzl", "memory_efficient_depset")
load(":output_files.bzl", "output_files")
load(":processed_target.bzl", "processed_target")
load(":target_id.bzl", "get_id")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "process_swiftmodules",
)

def process_non_xcode_target(
        *,
        ctx,
        target,
        attrs,
        automatic_target_info,
        transitive_infos):
    """Gathers information about a non-Xcode target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    build_mode = ctx.attr._build_mode
    cc_info = target[CcInfo] if CcInfo in target else None
    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    if AppleResourceBundleInfo in target and AppleResourceInfo not in target:
        # `apple_bundle_import` returns a `AppleResourceBundleInfo` and also
        # a `AppleResourceInfo`, so we use that to exclude it
        if not getattr(
            ctx.rule.attr,
            automatic_target_info.infoplists[0],
            None,
        ):
            fail("""\
rules_xcodeproj requires {} to have `{}` set.
""".format(target.label, automatic_target_info.infoplists[0]))

        resource_bundle_informations = [
            struct(
                id = get_id(
                    label = target.label,
                    configuration = calculate_configuration(
                        bin_dir_path = ctx.bin_dir.path,
                    ),
                ),
                bundle_id = getattr(
                    ctx.rule.attr,
                    automatic_target_info.bundle_id,
                ),
            ),
        ]
    else:
        resource_bundle_informations = None

    (
        compilation_providers,
        _,
    ) = comp_providers.collect(
        cc_info = cc_info,
        objc = objc,
        is_xcode_target = False,
        # Since we don't use the returned `implementation_compilation_context`,
        # we can pass `[]` here
        transitive_implementation_providers = [],
    )
    linker_inputs = linker_input_files.collect(
        target = target,
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
    )
    swiftmodules = process_swiftmodules(swift_info = swift_info)

    dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        transitive_infos = transitive_infos,
    )

    mergable_xcode_library_targets = memory_efficient_depset(
        transitive = [
            info.mergable_xcode_library_targets
            for info in transitive_infos
        ]
    )

    (_, provider_inputs) = input_files.collect(
        ctx = ctx,
        target = target,
        attrs = attrs,
        unfocused = None,
        id = None,
        platform = None,
        is_bundle = False,
        product = None,
        linker_inputs = linker_inputs,
        automatic_target_info = automatic_target_info,
        transitive_infos = transitive_infos,
    )
    (_, provider_outputs) = output_files.merge(
        transitive_infos = transitive_infos,
    )

    return processed_target(
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        inputs = provider_inputs,
        lldb_context = lldb_contexts.collect(
            build_mode = build_mode,
            id = None,
            is_swift = False,
            # TODO: Should we still collect this?
            swift_sub_params = None,
            swiftmodules = swiftmodules,
            transitive_infos = transitive_infos,
        ),
        mergable_xcode_library_targets = mergable_xcode_library_targets,
        outputs = provider_outputs,
        resource_bundle_informations = resource_bundle_informations,
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
    )
