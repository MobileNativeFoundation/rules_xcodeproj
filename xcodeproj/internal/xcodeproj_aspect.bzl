"""Implementation of the `xcodeproj_aspect` aspect."""

load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "SwiftInfo",
    "swift_clang_module_aspect",
)
load(
    ":default_input_file_attributes_aspect.bzl",
    "default_input_file_attributes_aspect",
)
load(":providers.bzl", "XcodeProjInfo")
load(":target.bzl", "process_target")

# Utility

def _should_ignore_attr(attr):
    return (
        # We don't want to include implicit dependencies
        attr.startswith("_") or
        # These are actually Starklark methods, so ignore them
        attr in ("to_json", "to_proto")
    )

def _create_dependent_provider_info(attr, type_name, provider):
    return struct(
        attr = attr,
        type_name = type_name,
        provider = provider,
    )

def _transitive_infos(*, ctx):
    xcodeproj_infos = []
    swift_info_dep_prov_infos = []

    # buildifier: disable=uninitialized
    def _process_dep(attr, dep):
        if type(dep) != "Target":
            return
        if XcodeProjInfo in dep:
            xcodeproj_infos.append((attr, dep[XcodeProjInfo]))
        if SwiftInfo in dep:
            swift_info_dep_prov_infos.append(
                _create_dependent_provider_info(attr, "SwiftInfo", dep[SwiftInfo]),
            )

    for attr in dir(ctx.rule.attr):
        if _should_ignore_attr(attr):
            continue
        dep = getattr(ctx.rule.attr, attr)
        if type(dep) == "list":
            for dep in dep:
                _process_dep(attr, dep)
        else:
            _process_dep(attr, dep)

    return xcodeproj_infos, swift_info_dep_prov_infos

# Aspect

def _xcodeproj_aspect_impl(target, ctx):
    xcodeproj_infos, swift_info_dep_prov_infos = _transitive_infos(ctx = ctx)
    return [
        process_target(
            ctx = ctx,
            target = target,
            transitive_infos = xcodeproj_infos,
            swift_info_dep_prov_infos = swift_info_dep_prov_infos,
        ),
    ]

xcodeproj_aspect = aspect(
    implementation = _xcodeproj_aspect_impl,
    attr_aspects = ["*"],
    attrs = {
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
    fragments = ["apple", "cpp"],
    requires = [default_input_file_attributes_aspect, swift_clang_module_aspect],
)
