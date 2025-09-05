"""
Aspect that collects the outputs of all actions that we want to cache for
developers in a given build.

Useful to be able to build and cache actions on CI, without having to link,
bundle, or codesign as well (which we don't cache anyway).
"""

load("@build_bazel_rules_apple//apple:providers.bzl", "AppleResourceInfo")
load("@build_bazel_rules_swift//swift:providers.bzl", "SwiftInfo")

_BUNDLING_RULE_KINDS = set([
    "ios_app_clip",
    "ios_application",
    "ios_build_test",
    "ios_extension",
    "macos_application",
    "macos_build_test",
    "macos_extension",
    "tvos_application",
    "tvos_build_test",
    "tvos_extension",
    "visionos_application",
    "visionos_build_test",
    "visionos_extension",
    "watchos_application",
    "watchos_build_test",
    "watchos_extension",
    "_ios_internal_ui_test_bundle",
    "_ios_internal_unit_test_bundle",
    "_macos_internal_ui_test_bundle",
    "_macos_internal_unit_test_bundle",
    "_tvos_internal_ui_test_bundle",
    "_tvos_internal_unit_test_bundle",
    "_visionos_internal_ui_test_bundle",
    "_visionos_internal_unit_test_bundle",
    "_watchos_internal_ui_test_bundle",
    "_watchos_internal_unit_test_bundle",
])

_COMPILE_MNEMONICS = set([
    "CppCompile",
    "ObjcCompile",
    "SwiftCompile",
])

_RESOURCE_MNEMONICS = set([
    "AlternateIconsInsert",
    "AppIntentsMetadataProcessor",
    "AssetCatalogCompile",
    "CompileInfoPlist",
    "CompilePlist",
    "CompileRootInfoPlist",
    "CompileStrings",
    "CompileTextureAtlas",
    "CompileXCStrings",
    "CopyPng",
    "MappingModelCompile",
    "MetalCompile",
    "MlmodelCompile",
    "MomCompile",
    "ProcessEntitlementsFiles",
    "ProcessDEREntitlements",
    "ProcessSimulatorEntitlementsFile",
    "StoryboardCompile",
    "StoryboardLink",
    "XibCompile",
])

def _xcodeproj_cache_warm_aspect_impl(target, ctx):
    compile_outs = []
    resource_outs = []

    if ctx.rule.kind in _BUNDLING_RULE_KINDS:
        deps = (
            ctx.rule.attr.deps +
            getattr(ctx.rule.attr, "extensions", []) +
            getattr(ctx.rule.attr, "frameworks", [])
        )

        # Collect already processed resources from dependencies
        resource_info = target[AppleResourceInfo]
        dep_resources = [
            resources
            for (_, _, resources) in (
                resource_info.processed +
                resource_info.unprocessed
            )
        ]

        # Collect resources from this target
        self_resources = [
            action.outputs
            for action in target.actions
            if action.mnemonic in _RESOURCE_MNEMONICS
        ]

        resource_outs = self_resources + dep_resources
    elif ctx.rule.kind == "mixed_language_library":
        deps = [
            ctx.rule.attr.swift_target,
            ctx.rule.attr.clang_target,
        ]
    elif ctx.rule.kind == "test_suite":
        deps = ctx.rule.attr.tests
    elif ctx.rule.kind == "ios_build_test":
        deps = ctx.rule.attr.targets
    elif ctx.rule.kind == "xcodeproj":
        deps = (
            getattr(ctx.rule.attr, "top_level_device_targets", []) +
            getattr(ctx.rule.attr, "top_level_simulator_targets", [])
        )
    elif CcInfo in target or SwiftInfo in target:
        compile_outs = [
            action.outputs
            for action in target.actions
            if action.mnemonic in _COMPILE_MNEMONICS
        ]

        if compile_outs:
            # If this target compiled code, we don't need the transitive
            # outputs, since they are implicitly compiled
            deps = []
        else:
            # Otherwise collect the transitive outputs
            deps = (
                getattr(ctx.rule.attr, "deps", []) +
                getattr(ctx.rule.attr, "implementation_deps", []) +
                getattr(ctx.rule.attr, "private_deps", [])
            )
    else:
        deps = getattr(ctx.rule.attr, "deps", [])

    return [
        OutputGroupInfo(
            compiles = depset(
                transitive = compile_outs + [
                    dep[OutputGroupInfo].compiles
                    for dep in deps
                    if (
                        OutputGroupInfo in dep and
                        hasattr(dep[OutputGroupInfo], "compiles")
                    )
                ],
            ),
            resources = depset(
                transitive = resource_outs + [
                    dep[OutputGroupInfo].resources
                    for dep in deps
                    if (
                        OutputGroupInfo in dep and
                        hasattr(dep[OutputGroupInfo], "resources")
                    )
                ],
            ),
        ),
    ]

xcodeproj_cache_warm_aspect = aspect(
    implementation = _xcodeproj_cache_warm_aspect_impl,
    attr_aspects = [
        "deps",
        "implementation_deps",
        "private_deps",

        # `*_application`
        "extensions",
        "frameworks",

        # `mixed_language_library`
        "clang_target",
        "swift_target",

        # `test_suite`
        "tests",

        # `*_build_test`
        "targets",

        # `xcodeproj`
        "top_level_device_targets",
        "top_level_simulator_targets",
    ],
)
