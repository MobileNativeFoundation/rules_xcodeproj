load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
    "swift_library_group",
)
load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("@rules_python//python:defs.bzl", "py_library")

# See the note in __init__.py for why this is needed.
py_library(
    name = "py_init_shim",
    testonly = 1,
    srcs = ["__init__.py"],
    visibility = ["//tools:__subpackages__"],
)

# Release

exports_files(["MODULE.bazel"])

genrule(
    name = "release_MODULE.bazel",
    srcs = ["MODULE.bazel"],
    outs = ["MODULE.release.bazel"],
    cmd = """\
set -euo pipefail

perl -0777 -pe 's/\n# Non-release dependencies.*//s' $< > $@
    """,
    tags = ["manual"],
)

filegroup(
    name = "release_files",
    srcs = [
        "LICENSE",
        ":release_MODULE.bazel",
        "//tools:release_files",
        "//xcodeproj:release_files",
    ],
    tags = ["manual"],
    visibility = ["//distribution:__subpackages__"],
)

# Buildifier

_BUILDIFIER_EXCLUDE_PATTERNS = [
    "./.git/*",
    "./xcodeproj/internal/templates/*",
    "./test/fixtures/**/generated/*",
    "**/bazel-output-base/*",
    "**/test/fixtures/generated/*",
    "**/.rules_xcodeproj/*",
    "**/*.xcodeproj/*",
]

_BUILDIFIER_WARNINGS = [
    "attr-cfg",
    "attr-non-empty",
    "attr-output-default",
    "attr-single-file",
    "build-args-kwargs",
    "bzl-visibility",
    "confusing-name",
    "constant-glob",
    "ctx-actions",
    "ctx-args",
    "deprecated-function",
    "depset-items",
    "depset-iteration",
    "depset-union",
    "dict-concatenation",
    "dict-method-named-arg",
    "duplicated-name",
    "filetype",
    "function-docstring",
    "function-docstring-args",
    "function-docstring-header",
    "function-docstring-return",
    "git-repository",
    "http-archive",
    "integer-division",
    "keyword-positional-params",
    "list-append",
    "load",
    "load-on-top",
    "module-docstring",
    "name-conventions",
    "native-py",
    "no-effect",
    "out-of-order-load",
    "output-group",
    "overly-nested-depset",
    "package-name",
    "package-on-top",
    "positional-args",
    "print",
    "provider-params",
    "redefined-variable",
    "repository-name",
    "return-value",
    "rule-impl-return",
    "same-origin-load",
    "skylark-comment",
    "skylark-docstring",
    "string-iteration",
    "uninitialized",
    "unnamed-macro",
    "unreachable",
    "unsorted-dict-items",
    "unused-variable",
]

buildifier(
    name = "buildifier.check",
    exclude_patterns = _BUILDIFIER_EXCLUDE_PATTERNS,
    lint_mode = "warn",
    lint_warnings = _BUILDIFIER_WARNINGS,
    mode = "diff",
    tags = ["manual"],
)

buildifier(
    name = "buildifier.fix",
    exclude_patterns = _BUILDIFIER_EXCLUDE_PATTERNS,
    lint_mode = "fix",
    lint_warnings = _BUILDIFIER_WARNINGS,
    mode = "fix",
    tags = ["manual"],
)

swift_library_group(
    name = "SwiftBuild",
    visibility = ["//visibility:public"],
    deps = [":SwiftBuild.rspm"],
)

swift_library(
    name = "SwiftBuild.rspm",
    package_name = "SwiftBuild",
    srcs = [
        "@swiftpkg_swift_build//:Sources/SwiftBuild/CompatibilityShims.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ConsoleCommands/SWBServiceConsoleBuildCommand.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ConsoleCommands/SWBServiceConsoleBuildCommandProtocol.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ConsoleCommands/SWBServiceConsoleCreateXCFrameworkCommand.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ConsoleCommands/SWBServiceConsoleGeneralCommands.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ConsoleCommands/SWBServiceConsoleSessionCommands.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ConsoleCommands/SWBServiceConsoleXcodeCommands.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/BuildConfig.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/BuildFile.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/BuildPhases.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/BuildRule.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/BuildSettings.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/CustomTask.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/ImpartedBuildProperties.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/PlatformFilter.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/Project.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/ProjectModel.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/References.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/SandboxingOverride.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/TargetDependency.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/ProjectModel/Targets.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildAction.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildOperation.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildOperationBacktraceFrame.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildParameters.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildRequest.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildService.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildServiceConnection.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildServiceConsole.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBBuildServiceSession.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBChannel.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBClientExchangeSupport.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBDocumentationSupport.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBIndexingSupport.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBLocalizationSupport.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBMacroEvaluation.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBMacroEvaluationScope.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBPreviewSupport.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBProductPlannerSupport.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBPropertyList.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBProvisioningTaskInputs.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBSystemInfo.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBTargetGUID.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBTerminal.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBUserInfo.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBWorkspaceInfo.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SWBuildMessage+Protocol.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SwiftBuild.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/SwiftBuildVersion.swift",
        "@swiftpkg_swift_build//:Sources/SwiftBuild/TerminalAttributes.swift",
    ],
    always_include_developer_search_paths = True,
    copts = [
        "-DSWIFT_PACKAGE",
        "-Xcc",
        "-DSWIFT_PACKAGE",
        "-DUSE_STATIC_PLUGIN_INITIALIZATION",
    ],
    features = [
        "swift.experimental.AccessLevelOnImport",
    ],
    module_name = "SwiftBuild",
    tags = ["manual"],
    deps = [
        "@swiftpkg_swift_build//:SWBCSupport.rspm",
        "@swiftpkg_swift_build//:SWBCore.rspm",
        "@swiftpkg_swift_build//:SWBProjectModel.rspm",
        "@swiftpkg_swift_build//:SWBProtocol.rspm",
        "@swiftpkg_swift_build//:SWBUtil.rspm",
    ],
    alwayslink = True,
)
