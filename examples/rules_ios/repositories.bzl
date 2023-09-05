"""Module extension for loading dependencies not yet compatible with bzlmod."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# buildifier: disable=function-docstring
def non_bzlmod_dependencies():
    # TODO: Undo this `rules_apple` bump once there's a new version of `rules_ios` consuming a newer `rules_apple`
    http_archive(
        name = "build_bazel_rules_apple",
        sha256 = "f89786b86c19f0e99a99a03dc64005ba13e715dbc49959239bad0620c66cdc83",
        strip_prefix = "rules_apple-4b4f645b75ba1df7e70244b696151bb2172ac8f2",
        url = "https://github.com/bazelbuild/rules_apple/archive/4b4f645b75ba1df7e70244b696151bb2172ac8f2.tar.gz",
    )

    http_archive(
        name = "build_bazel_rules_ios",
        sha256 = "88dc6c5d1aade86bc4e26cbafa62595dffd9f3821f16e8ba8461f372d66a5783",
        url = "https://github.com/bazel-ios/rules_ios/releases/download/2.1.0/rules_ios.2.1.0.tar.gz",
    )

non_module_deps = module_extension(implementation = lambda _: non_bzlmod_dependencies())
