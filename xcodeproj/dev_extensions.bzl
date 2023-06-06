"""Module extension for loading dev dependencies not yet compatible with bzlmod."""

load(
    "//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dev_dependencies",
)

dev_non_module_deps = module_extension(implementation = lambda _: xcodeproj_rules_dev_dependencies())
