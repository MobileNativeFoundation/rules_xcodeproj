""" Functions for processing non-Xcode targets """

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":compilation_providers.bzl", "compilation_providers")
load(":configuration.bzl", "calculate_configuration")
load(":input_files.bzl", "input_files")
load(":legacy_processed_targets.bzl", "legacy_processed_targets")
load(
    ":legacy_target_properties.bzl",
    "process_dependencies",
    "process_swiftmodules",
)
load(":linker_input_files.bzl", "linker_input_files")
load(":lldb_contexts.bzl", "lldb_contexts")
load(":output_files.bzl", "output_files")
load(":target_id.bzl", "get_id")

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
        A from `processed_target`.
    """
    build_mode = ctx.attr._build_mode

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
        cc_info = target[CcInfo] if CcInfo in target else None,
        objc = target[apple_common.Objc] if apple_common.Objc in target else None,
    )
    linker_inputs = linker_input_files.collect(
        target = target,
        automatic_target_info = automatic_target_info,
        compilation_providers = target_compilation_providers,
    )
    swiftmodules = process_swiftmodules(
        swift_info = target[SwiftInfo] if SwiftInfo in target else None,
    )

    direct_dependencies, transitive_dependencies = process_dependencies(
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

    return legacy_processed_targets.make(
        compilation_providers = provider_compilation_providers,
        direct_dependencies = direct_dependencies,
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
