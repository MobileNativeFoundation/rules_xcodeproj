"""An example aspect to exercise Xcode target selection."""

# buildifier: disable=bzl-visibility
load("@build_bazel_rules_apple//apple/internal:resources.bzl", "resources")

DepCollectorInfo = provider(
    "Collects names of transitive dependencies of a target",
    fields = {"dep_names": "The names of transitive dependencies."},
)

def _deps_aspect_impl(_target, ctx):
    return [
        DepCollectorInfo(
            dep_names = depset(
                [ctx.rule.attr.name],
                transitive = [
                    dep[DepCollectorInfo].dep_names
                    for dep in getattr(ctx.rule.attr, "deps", [])
                ],
            ),
        ),
    ]

_deps_aspect = aspect(
    implementation = _deps_aspect_impl,
    attr_aspects = ["*"],
)

def _dep_resources_collector_impl(ctx):
    all_deps = depset(
        transitive = [dep[DepCollectorInfo].dep_names for dep in ctx.attr.deps],
    ).to_list()

    output = ctx.actions.declare_file("bucket/deps.txt")
    ctx.actions.run_shell(
        outputs = [output],
        command = "echo '{}' > {}".format("\n".join(all_deps), output.path),
    )

    return resources.bucketize(
        resources = [output],
        parent_dir_param = "bucket",
    )

dep_resources_collector = rule(
    implementation = _dep_resources_collector_impl,
    attrs = {
        "deps": attr.label_list(
            aspects = [_deps_aspect],
        ),
    },
)
