load("@build_bazel_rules_apple//apple:macos.bzl", "macos_application", "macos_build_test", "macos_dynamic_framework")
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_swift//mixed_language:mixed_language_library.bzl", "mixed_language_library")
load("@rules_xcodeproj//xcodeproj:xcodeproj.bzl", "xcodeproj")
load("@rules_xcodeproj//xcodeproj:xcschemes.bzl", "xcschemes")

package(default_visibility = ["//visibility:public"])

swift_library(
    name = "Views",
    srcs = ["PreviewView.swift"],
    copts = ["-whole-module-optimization"],
    module_name = "Views",
    deps = [":Dependency"],
)

genrule(
    name = "generated_view",
    srcs = ["PreviewView.swift"],
    outs = ["GeneratedPreviewView.swift"],
    cmd = "cp $< $@",
)

swift_library(
    name = "ExplicitViews",
    srcs = [":generated_view"],
    features = ["swift.use_explicit_swift_module_map"],
    module_name = "ExplicitViews",
    deps = [":Dependency"],
)

macos_build_test(
    name = "ExplicitViewsBuild",
    minimum_os_version = "14.0",
    targets = [":ExplicitViews"],
)

swift_library(
    name = "Dependency",
    srcs = ["Dependency.swift"],
    module_name = "Dependency",
)

mixed_language_library(
    name = "Mixed",
    hdrs = ["Mixed.h"],
    clang_srcs = [
        ":generated_c",
        "Mixed.cpp",
        "Mixed.m",
        "Mixed.mm",
    ],
    enable_modules = True,
    module_name = "Mixed",
    swift_srcs = ["Mixed.swift"],
)

genrule(
    name = "generated_c",
    srcs = ["Mixed.c"],
    outs = ["GeneratedMixed.c"],
    cmd = "cp $< $@",
)

swift_library(
    name = "AppSources",
    srcs = ["PreviewApp.swift"],
    module_name = "PreviewApp",
    deps = [
        ":Mixed",
        ":Views",
    ],
)

macos_application(
    name = "MacApp",
    bundle_id = "org.rules-xcodeproj.preview-example",
    infoplists = ["Info.plist"],
    minimum_os_version = "14.0",
    deps = [":AppSources"],
)

ios_application(
    name = "IOSApp",
    bundle_id = "org.rules-xcodeproj.preview-example",
    families = [
        "iphone",
        "ipad",
    ],
    infoplists = ["Info.plist"],
    minimum_os_version = "17.0",
    deps = [":AppSources"],
)

swift_library(
    name = "FrameworkViews",
    srcs = ["PreviewView.swift"],
    copts = ["-whole-module-optimization"],
    module_name = "FrameworkViews",
    deps = [":Dependency"],
)

macos_dynamic_framework(
    name = "ViewFramework",
    bundle_id = "org.rules-xcodeproj.preview-framework",
    bundle_name = "FrameworkViews",
    infoplists = ["Info.plist"],
    minimum_os_version = "14.0",
    deps = [":FrameworkViews"],
)

xcodeproj(
    name = "xcodeproj",
    bazel_path = "bazel",
    default_xcode_configuration = "Debug",
    preview_xcode_configurations = ["Previews"],
    project_name = "Previews",
    top_level_targets = [
        ":MacApp",
        ":IOSApp",
        ":ViewFramework",
        ":ExplicitViewsBuild",
    ],
    # The same Bazel transition deliberately feeds both Xcode configurations.
    xcode_configurations = {
        "Debug": {},
        "Previews": {},
    },
    xcschemes = [
        xcschemes.scheme(
            name = "Explicit Previews",
            run = xcschemes.run(
                build_targets = [
                    xcschemes.top_level_anchor_target(
                        ":ExplicitViewsBuild",
                        library_targets = [":ExplicitViews"],
                    ),
                ],
                xcode_configuration = "Previews",
            ),
        ),
        xcschemes.scheme(
            name = "Mac Previews",
            run = xcschemes.run(
                launch_target = ":MacApp",
                xcode_configuration = "Previews",
            ),
        ),
    ] + [
        xcschemes.scheme(
            name = name,
            run = xcschemes.run(
                build_targets = [target],
                xcode_configuration = "Previews",
            ),
        )
        for name, target in [
            ("Framework Previews", ":ViewFramework"),
            ("iOS Previews", ":IOSApp"),
        ]
    ] + [
        xcschemes.scheme(
            name = target + " Previews",
            run = xcschemes.run(
                build_targets = [
                    xcschemes.top_level_anchor_target(
                        ":MacApp",
                        library_targets = [":" + target],
                    ),
                ],
                xcode_configuration = "Previews",
            ),
        )
        for target in [
            "Views",
            "Mixed",
        ]
    ],
)
