"""Module extension for loading dependencies not yet compatible with bzlmod."""

load(
    "//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

internal = module_extension(implementation = lambda mctx: xcodeproj_rules_dependencies(mctx, internal_only = True))

non_module_deps = module_extension(implementation = lambda mctx: xcodeproj_rules_dependencies(mctx, include_bzlmod_ready_dependencies = False))
