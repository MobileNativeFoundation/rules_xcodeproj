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
load(":lldb_contexts.bzl", "lldb_contexts")
load(":output_files.bzl", "output_files")
load(":processed_target.bzl", "processed_target")
load(":providers.bzl", "XcodeProjInfo")
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
    is_swift = SwiftInfo in target
    swift_info = target[SwiftInfo] if is_swift else None

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

    deps_infos = [
        dep[XcodeProjInfo]
        for attr in automatic_target_info.implementation_deps
        for dep in getattr(ctx.rule.attr, attr, [])
        if XcodeProjInfo in dep
    ]

    compilation_providers = comp_providers.collect(
        cc_info = cc_info,
        objc = objc,
        swift_info = swift_info,
        is_xcode_target = False,
        transitive_implementation_providers = [
            info.compilation_providers
            for info in deps_infos
        ],
    )
    linker_inputs = linker_input_files.collect(
        target = target,
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
    )
    swiftmodules = process_swiftmodules(swift_info = swift_info)

    dependencies, transitive_dependencies = process_dependencies(
        automatic_target_info = automatic_target_info,
        transitive_infos = transitive_infos,
    )

    mergable_xcode_library_targets = [
        struct(
            id = target.id,
            product_path = target.product.file_path,
        )
        for target, providers in [
            (info.xcode_target, info.compilation_providers)
            for (attr, info) in transitive_infos
        ]
        if providers._is_xcode_library_target
    ]

    return processed_target(
        automatic_target_info = automatic_target_info,
        compilation_providers = compilation_providers,
        dependencies = dependencies,
        inputs = input_files.collect(
            ctx = ctx,
            target = target,
            unfocused = None,
            id = None,
            platform = None,
            is_bundle = False,
            product = None,
            linker_inputs = linker_inputs,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        ),
        lldb_context = lldb_contexts.collect(
            id = None,
            is_swift = is_swift,
            # TODO: Should we still collect this?
            clang_opts = [],
            swiftmodules = swiftmodules,
            transitive_infos = [
                info
                for attr, info in transitive_infos
                if (info.target_type in
                    automatic_target_info.xcode_targets.get(attr, [None]))
            ],
        ),
        mergable_xcode_library_targets = mergable_xcode_library_targets,
        outputs = output_files.merge(
            ctx = ctx,
            automatic_target_info = automatic_target_info,
            transitive_infos = transitive_infos,
        ),
        resource_bundle_informations = resource_bundle_informations,
        search_paths = None,
        transitive_dependencies = transitive_dependencies,
        xcode_target = None,
    )
