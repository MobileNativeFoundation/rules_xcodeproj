"""Module containing implementation functions for the incremental \
`xcodeproj_aspect` aspect."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":incremental_xcodeprojinfos.bzl", "incremental_xcodeprojinfos")
load(
    ":provisioning_profiles.bzl",
    "XcodeProjProvisioningProfileInfo",
    "provisioning_profiles",
)
load(":xcodeprojinfo.bzl", "XcodeProjInfo")

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

def _transitive_infos(*, attrs, rule_attr):
    transitive_infos = []

    # TODO: Have `XcodeProjAutomaticTargetProcessingInfo` tell us which
    # attributes to look at. About 7% of an example pprof trace is spent on
    # `_should_ignore_attr` and the type checks below. If we had a list of
    # attributes with the types (list or not) we could eliminate that overhead.
    for attr in attrs:
        if _should_ignore_attr(attr):
            continue

        dep = getattr(rule_attr, attr)

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

def _xcodeproj_incremental_aspect_attrs(
        *,
        focused_labels,
        generator_name,
        unfocused_labels):
    return {
        "_allow_remote_write_target_build_settings": attr.label(
            default = Label(
                "//xcodeproj:allow_remote_write_target_build_settings",
            ),
            providers = [BuildSettingInfo],
        ),
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
        "_link_params_processor": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/params_processors:incremental_link_params_processor",
            ),
            executable = True,
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
    }

def _xcodeproj_incremental_aspect_impl(target, ctx):
    providers = []

    if XcodeProjInfo not in target:
        # Only create a `XcodeProjInfo` if the target hasn't already created
        # one
        rule_attr = ctx.rule.attr

        attrs = dir(rule_attr)
        info = incremental_xcodeprojinfos.make(
            ctx = ctx,
            target = target,
            attrs = attrs,
            rule_attr = rule_attr,
            rule_kind = ctx.rule.kind,
            transitive_infos = _transitive_infos(
                attrs = attrs,
                rule_attr = rule_attr,
            ),
        )
        if info:
            providers.append(info)

    if XcodeProjProvisioningProfileInfo not in target:
        # Only create an `XcodeProjProvisioningProfileInfo` if the target hasn't
        # already created one
        providers.append(
            provisioning_profiles.create_provider(target = target),
        )

    return providers

xcodeproj_incremental_aspect = struct(
    attrs = _xcodeproj_incremental_aspect_attrs,
    impl = _xcodeproj_incremental_aspect_impl,
)
