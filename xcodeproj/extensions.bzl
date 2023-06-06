"""Module extension for loading dependencies not yet compatible with bzlmod."""

load(
    "//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

internal = module_extension(implementation = lambda _: xcodeproj_rules_dependencies(internal_only = True))

non_module_deps = module_extension(implementation = lambda _: xcodeproj_rules_dependencies(include_bzlmod_ready_dependencies = False))
