"""Implementation of the `xcodeproj_scheme` rule."""

load(":providers.bzl", "XcodeProjSchemeInfo")

def _xcodeproj_scheme_impl(ctx):
    return [
        XcodeProjSchemeInfo(
            name = ctx.attr.scheme_name,
        ),
    ]

xcodeproj_scheme = rule(
    doc = "Provides information about a custom scheme to the `xcodeproj` rule.",
    implementation = _xcodeproj_scheme_impl,
    attrs = {
        "scheme_name": attr.string(
            doc = "The name of the scheme.",
            mandatory = True,
        ),
    },
)
