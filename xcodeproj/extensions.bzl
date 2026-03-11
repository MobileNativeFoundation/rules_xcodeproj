"""Module extension for loading dependencies not yet compatible with bzlmod."""

load("@bazel_skylib//lib:modules.bzl", "modules")
load(":repositories.bzl", "xcodeproj_rules_dev_repos", "xcodeproj_rules_repos")

rules_repos = modules.as_extension(xcodeproj_rules_repos)
rules_dev_repos = modules.as_extension(xcodeproj_rules_dev_repos)
