"""Module containing implementation functions for the legacy \
`xcodeproj_aspect` aspect."""

load(":legacy_xcodeprojinfos.bzl", "legacy_xcodeprojinfos")
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

def _xcodeproj_legacy_aspect_attrs(build_mode, generator_name):
    return {
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
        "_generator_name": attr.string(default = generator_name),
        "_swift_compiler_params_processor": attr.label(
            cfg = "exec",
            default = Label(
                "//tools/params_processors:swift_compiler_params_processor",
            ),
            executable = True,
        ),
        "_xcode_config": attr.label(
            default = configuration_field(
                name = "xcode_config_label",
                fragment = "apple",
            ),
        ),
    }

def _xcodeproj_legacy_aspect_impl(target, ctx):
    """Implementation function for the `xcodeproj_aspect` aspect.

    Args:
        target: The `Target` the aspect is propagating over.
        ctx: The context for the aspect.

    Returns:
        A `list` of providers to add to the target. The elements of the list
        will include `XcodeProjInfo` and `XcodeProjProvisioningProfileInfo` if
        the target doesn't already have them.
    """
    providers = []

    if XcodeProjInfo not in target:
        # Only create an `XcodeProjInfo` if the target hasn't already created
        # one
        rule_attr = ctx.rule.attr

        attrs = dir(rule_attr)
        info = legacy_xcodeprojinfos.make(
            ctx = ctx,
            build_mode = ctx.attr._build_mode,
            attrs = attrs,
            rule_attr = rule_attr,
            rule_kind = ctx.rule.kind,
            target = target,
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

xcodeproj_legacy_aspect = struct(
    attrs = _xcodeproj_legacy_aspect_attrs,
    impl = _xcodeproj_legacy_aspect_impl,
)
