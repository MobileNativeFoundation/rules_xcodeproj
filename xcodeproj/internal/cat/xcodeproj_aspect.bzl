"""Implementation of the `xcodeproj_aspect` aspect."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "use_cpp_toolchain")
load(
    "//xcodeproj/internal:providers.bzl",
    "XcodeProjProvisioningProfileInfo",
)
load(
    ":providers.bzl",
    "XcodeProjInfo",
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
        # Exclude implicit dependencies, except the ones added by
        # `swift_{grpc,proto}_library`.
        (attr[0] == "_" and attr != "_proto_support") or
        # These are actually Starklark methods, so ignore them
        attr in _IGNORE_ATTR
    )

def _transitive_infos(*, ctx, attrs):
    transitive_infos = []

    # TODO: Have `XcodeProjAutomaticTargetProcessingInfo` tell us which
    # attributes to look at. About 7% of an example pprof trace is spent on
    # `_should_ignore_attr` and the type checks below. If we had a list of
    # attributes with the types (list or not) we could eliminate that overhead.
    for attr in attrs:
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
        # Only create a `XcodeProjInfo` if the target hasn't already created
        # one
        attrs = dir(ctx.rule.attr)
        info = create_xcodeprojinfo(
            ctx = ctx,
            build_mode = ctx.attr._build_mode,
            target = target,
            attrs = attrs,
            transitive_infos = _transitive_infos(
                ctx = ctx,
                attrs = attrs,
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

def make_xcodeproj_aspect(
        *,
        build_mode,
        focused_labels,
        generator_name,
        owned_extra_files,
        unfocused_labels):
    return aspect(
        implementation = _xcodeproj_aspect_impl,
        attr_aspects = ["*"],
        attrs = {
            "_build_mode": attr.string(default = build_mode),
            "_cc_compiler_params_processor": attr.label(
                cfg = "exec",
                default = Label(
                    "//tools/params_processors:cc_compiler_params_processor",
                ),
                executable = True,
            ),
            "_cc_toolchain": attr.label(default = Label(
                "@bazel_tools//tools/cpp:current_cc_toolchain",
            )),
            "_colorize": attr.label(
                default = Label("//xcodeproj:color"),
                providers = [BuildSettingInfo],
            ),
            "_focused_labels": attr.string_list(default = focused_labels),
            "_generator_name": attr.string(default = generator_name),
            "_owned_extra_files": attr.label_keyed_string_dict(
                allow_files = True,
                default = owned_extra_files,
            ),
            "_target_build_settings_generator": attr.label(
                cfg = "exec",
                default = Label(
                    "//tools/generators/target_build_settings:universal_target_build_settings",
                ),
                executable = True,
            ),
            "_unfocused_labels": attr.string_list(default = unfocused_labels),
            "_xcode_config": attr.label(
                default = configuration_field(
                    name = "xcode_config_label",
                    fragment = "apple",
                ),
            ),
        },
        fragments = ["apple", "cpp", "objc"],
        toolchains = use_cpp_toolchain(),
    )
