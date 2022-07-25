""" Functions for processing non-Xcode targets """

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceBundleInfo",
    "AppleResourceInfo",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")
load(":compilation_providers.bzl", comp_providers = "compilation_providers")
load(":configuration.bzl", "get_configuration")
load(":input_files.bzl", "input_files")
load(":linker_input_files.bzl", "linker_input_files")
load(":output_files.bzl", "output_files")
load(":processed_target.bzl", "processed_target")
load(":target_id.bzl", "get_id")
load(
    ":target_properties.bzl",
    "process_dependencies",
    "should_bundle_resources",
)
load(":target_search_paths.bzl", "target_search_paths")

def process_non_xcode_target(
        *,
        ctx,
        target,
        automatic_target_info,
        transitive_infos):
    """Gathers information about a non-Xcode target.

    Args:
        ctx: The aspect context.
        target: The `Target` to process.
        automatic_target_info: The `XcodeProjAutomaticTargetProcessingInfo` for
            `target`.
        transitive_infos: A `list` of `depset`s of `XcodeProjInfo`s from the
            transitive dependencies of `target`.

    Returns:
        The value returned from `processed_target`.
    """
    cc_info = target[CcInfo] if CcInfo in target else None
    objc = target[apple_common.Objc] if apple_common.Objc in target else None
    swift_info = target[SwiftInfo] if SwiftInfo in target else None

    if AppleResourceBundleInfo in target and AppleResourceInfo not in target:
        # `apple_bundle_import` returns a `AppleResourceBundleInfo` and also
        # a `AppleResourceInfo`, so we use that to exclude it
        bundle_resources = should_bundle_resources(ctx = ctx)
        if bundle_resources and not getattr(
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
                    configuration = get_configuration(ctx),
                ),
                bundle_id = getattr(
                    ctx.rule.attr,
                    automatic_target_info.bundle_id,
                ),
            ),
        ]
    else:
        resource_bundle_informations = None

    compilation_providers = comp_providers.collect(
        cc_info = cc_info,
        objc = objc,
        swift_info = swift_info,
        is_xcode_target = False,
    )
    linker_inputs = linker_input_files.collect(
        ctx = ctx,
        compilation_providers = compilation_providers,
    )

    return processed_target(
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
        dependencies = process_dependencies(
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        ),
        inputs = input_files.collect(
            ctx = ctx,
            target = target,
            unfocused = None,
            id = None,
            platform = None,
            bundle_resources = False,
            is_bundle = False,
            linker_inputs = linker_inputs,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        ),
        outputs = output_files.merge(
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        ),
        resource_bundle_informations = resource_bundle_informations,
        search_paths = target_search_paths.make(
            compilation_providers = compilation_providers,
            bin_dir_path = ctx.bin_dir.path,
        ),
        xcode_target = None,
    )
