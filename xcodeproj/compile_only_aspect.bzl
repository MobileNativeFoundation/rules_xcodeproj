"""
Aspect that collects the outputs of all compile actions of a given build.
Useful to be able to build and cache compile actions on CI, without having to
link, bundle, or codesign as well (which we don't cache anyway).
"""

_DOWNSTREAM_VALID_RULE_KINDS = {
    "apple_dynamic_framework_import": None,
    "apple_dynamic_xcframework_import": None,
    "apple_static_framework_import": None,
    "apple_static_xcframework_import": None,
    "cc_binary": None,
    "ios_app_clip": None,
    "ios_application": None,
    "ios_extension": None,
    "ios_framework": None,
    "ios_ui_test": None,
    "ios_unit_test": None,
    "swift_binary": None,
    "swift_test": None,
    "_ios_internal_ui_test_bundle": None,
    "_ios_internal_unit_test_bundle": None,
    "_precompiled_apple_resource_bundle": None,
}

_SWIFT_LIBRARY_KINDS = [
    "swift_library",
    "swift_test",
]

def _compile_only_aspect_impl(target, ctx):
    outs = []
    deps = []
    if ctx.rule.kind in _DOWNSTREAM_VALID_RULE_KINDS or CcInfo in target:
        if ctx.rule.kind in _SWIFT_LIBRARY_KINDS:
            for action in target.actions:
                if action.mnemonic == "SwiftCompile":
                    outs = [action.outputs]
                    break
        elif ctx.rule.kind == "objc_library":
            outs = [
                action.outputs
                for action in target.actions
                if action.mnemonic == "ObjcCompile"
            ]
        deps = (
            getattr(ctx.rule.attr, "deps", []) +
            getattr(ctx.rule.attr, "implementation_deps", []) +
            getattr(ctx.rule.attr, "private_deps", [])
        )
        swift_target = getattr(ctx.rule.attr, "swift_target", None)
        if swift_target:
            deps.append(swift_target)
        clang_target = getattr(ctx.rule.attr, "clang_target", None)
        if clang_target:
            deps.append(clang_target)
    elif ctx.rule.kind == "test_suite":
        deps = ctx.rule.attr.tests
    elif ctx.rule.kind == "ios_build_test":
        deps = ctx.rule.attr.targets
    elif ctx.rule.kind == "xcodeproj":
        deps = (
            getattr(ctx.rule.attr, "top_level_device_targets", []) +
            getattr(ctx.rule.attr, "top_level_simulator_targets", [])
        )
    else:
        return []

    for dep in deps:
        if OutputGroupInfo in dep and not hasattr(dep[OutputGroupInfo], "compiles"):
            fail(target, dep)

    return [
        OutputGroupInfo(
            compiles = depset(
                transitive = outs + [
                    dep[OutputGroupInfo].compiles
                    for dep in deps
                    if OutputGroupInfo in dep
                ],
            ),
        ),
    ]

compile_only_aspect = aspect(
    implementation = _compile_only_aspect_impl,
    attr_aspects = [
        "deps",
        "implementation_deps",
        "private_deps",
        # from `mixed_language_library`
        "clang_target",
        "swift_target",
        # from `test_suite`
        "targets",
        # from `*_build_test`
        "tests",
        # from `xcodeproj`
        "top_level_device_targets",
        "top_level_simulator_targets",
    ],
)
