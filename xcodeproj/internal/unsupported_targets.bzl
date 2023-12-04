""" Functions for processing non-Xcode targets """

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":compilation_providers.bzl", "compilation_providers")
load(":configuration.bzl", "calculate_configuration")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":output_files.bzl", "output_files")
load(":processed_target.bzl", "processed_target")
load(":target_id.bzl", "get_id")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "process_swiftmodules",
)

def process_unsupported_target(
        *,
        ctx,
        target,
        attrs,
        automatic_target_info,
        rule_attr,
        transitive_infos):
    """Gathers information about a non-Xcode target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        attrs: `dir(ctx.rule.attr)` (as a performance optimization).
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        rule_attr: `ctx.rule.attr`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    build_mode = ctx.attr._build_mode
    cc_info = target[CcInfo] if CcInfo in target else None
    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    if AppleResourceBundleInfo in target and automatic_target_info.bundle_id:
        # `apple_bundle_import` returns a `AppleResourceBundleInfo` and also
        # a `AppleResourceInfo`, so we use that to exclude it
        resource_bundle_ids = [
            (
                get_id(
                    label = target.label,
                    configuration = calculate_configuration(
                        bin_dir_path = ctx.bin_dir.path,
                    ),
                ),
                getattr(
                    rule_attr,
                    automatic_target_info.bundle_id,
                ),
            ),
        ]
    else:
        resource_bundle_ids = None

    (
        target_compilation_providers,
        provider_compilation_providers,
    ) = compilation_providers.collect(
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
        compilation_providers = target_compilation_providers,
    )
    swiftmodules = process_swiftmodules(swift_info = swift_info)

    dependencies, transitive_dependencies = process_dependencies(
        build_mode = build_mode,
        transitive_infos = transitive_infos,
    )

    (_, provider_inputs) = input_files.collect(
        ctx = ctx,
        target = target,
        attrs = attrs,
        rule_attr = rule_attr,
        unfocused = None,
        id = None,
        platform = None,
        is_bundle = False,
        product = None,
        linker_inputs = linker_inputs,
        automatic_target_info = automatic_target_info,
        transitive_infos = transitive_infos,
    )
    provider_outputs = output_files.merge(
        transitive_infos = transitive_infos,
    )

    return processed_target(
        compilation_providers = provider_compilation_providers,
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
        outputs = provider_outputs,
        resource_bundle_ids = resource_bundle_ids,
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
    )
