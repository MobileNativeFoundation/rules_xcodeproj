"""Implementation of the `xcodeproj_aspect` aspect."""

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "use_cpp_toolchain")
load(
    ":default_automatic_target_processing_aspect.bzl",
    "default_automatic_target_processing_aspect",
)
load(
    ":providers.bzl",
    "XcodeProjAutomaticTargetProcessingInfo",
    "XcodeProjInfo",
    "XcodeProjProvisioningProfileInfo",
)
load(":provisioning_profiles.bzl", "provisioning_profiles")
load(":xcodeprojinfo.bzl", "create_xcodeprojinfo")

# Utility

_IGNORE_ATTR = {
    "to_json": None,
    "to_proto": None,
}

def _should_ignore_attr(attr):
    return (
        # We don't want to include implicit dependencies
        attr[0] == "_" or
        # These are actually Starklark methods, so ignore them
        attr in _IGNORE_ATTR
    )

def _transitive_infos(*, ctx, automatic_target_info):
    transitive_infos = []

    # TODO: Have `XcodeProjAutomaticTargetProcessingInfo` tell us which
    # attributes to look at. About 7% of an example pprof trace is spent on
    # `_should_ignore_attr` and the type checks below. If we had a list of
    # attributes with the types (list or not) we could eliminate that overhead.
    for attr in automatic_target_info.all_attrs:
        if _should_ignore_attr(attr):
            continue

        dep = getattr(ctx.rule.attr, attr)

        dep_type = type(dep)
        if dep_type == "list":
            if not dep or type(dep[0]) != "Target":
                continue
            for list_dep in dep:
                if XcodeProjInfo in list_dep:
                    transitive_infos.append((attr, list_dep[XcodeProjInfo]))
        elif dep_type == "Target" and XcodeProjInfo in dep:
            transitive_infos.append((attr, dep[XcodeProjInfo]))

    return transitive_infos

# Aspect

def _xcodeproj_aspect_impl(target, ctx):
    providers = []

    if XcodeProjInfo not in target:
        # Only create an `XcodeProjInfo` if the target hasn't already created
        # one
        info = create_xcodeprojinfo(
            ctx = ctx,
            build_mode = ctx.attr._build_mode,
            target = target,
            transitive_infos = _transitive_infos(
                ctx = ctx,
                automatic_target_info = (
                    target[XcodeProjAutomaticTargetProcessingInfo]
                ),
            ),
        )
        if info:
            providers.append(info)

    if XcodeProjProvisioningProfileInfo not in target:
        # Only create an `XcodeProjProvisioningProfileInfo` if the target hasn't
        # already created one
        providers.append(
            provisioning_profiles.create_profileinfo(target = target),
        )

    return providers

def make_xcodeproj_aspect(*, build_mode):
    return aspect(
        implementation = _xcodeproj_aspect_impl,
        attr_aspects = ["*"],
        attrs = {
            "_build_mode": attr.string(default = build_mode),
            "_cc_toolchain": attr.label(default = Label(
                "@bazel_tools//tools/cpp:current_cc_toolchain",
            )),
            "_xcode_config": attr.label(
                default = configuration_field(
                    name = "xcode_config_label",
                    fragment = "apple",
                ),
            ),
        },
        fragments = ["apple", "cpp", "objc"],
        requires = [default_automatic_target_processing_aspect],
        toolchains = use_cpp_toolchain(),
    )
