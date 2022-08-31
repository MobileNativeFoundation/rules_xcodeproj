"""Implementation of the `xcodeproj_aspect` aspect."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "use_cpp_toolchain")
load(
    ":default_automatic_target_processing_aspect.bzl",
    "default_automatic_target_processing_aspect",
)
load(":providers.bzl", "XcodeProjInfo", "XcodeProjProvisioningProfileInfo")
load(":provisioning_profiles.bzl", "provisioning_profiles")
load(":xcodeprojinfo.bzl", "create_xcodeprojinfo")

# Utility

def _should_ignore_attr(attr):
    return (
        # We don't want to include implicit dependencies
        attr.startswith("_") or
        # These are actually Starklark methods, so ignore them
        attr in ("to_json", "to_proto")
    )

def _transitive_infos(*, ctx):
    transitive_infos = []
    for attr in dir(ctx.rule.attr):
        if _should_ignore_attr(attr):
            continue

        dep = getattr(ctx.rule.attr, attr)
        if type(dep) == "list":
            for dep in dep:
                if type(dep) == "Target" and XcodeProjInfo in dep:
                    transitive_infos.append((attr, dep[XcodeProjInfo]))
        elif type(dep) == "Target" and XcodeProjInfo in dep:
            transitive_infos.append((attr, dep[XcodeProjInfo]))

    return transitive_infos

# Aspect

def _xcodeproj_aspect_impl(target, ctx):
    providers = []

    if XcodeProjInfo not in target:
        # Only create an `XcodeProjInfo` if the target hasn't already created
        # one
        providers.append(
            create_xcodeprojinfo(
                ctx = ctx,
                target = target,
                transitive_infos = _transitive_infos(ctx = ctx),
            ),
        )

    if XcodeProjProvisioningProfileInfo not in target:
        # Only create an `XcodeProjProvisioningProfileInfo` if the target hasn't
        # already created one
        providers.append(
            provisioning_profiles.create_profileinfo(target = target),
        )

    return providers

xcodeproj_aspect = aspect(
    implementation = _xcodeproj_aspect_impl,
    attr_aspects = ["*"],
    attrs = {
        "_build_mode": attr.label(
            default = Label("//xcodeproj/internal:build_mode"),
            providers = [BuildSettingInfo],
        ),
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
