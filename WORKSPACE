workspace(name = "com_github_buildbuddy_io_rules_xcodeproj")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# TODO: Remove override and bump `xcodeproj_rules_dependencies` once
# rules_apple 1.1.0 is released. Needed for `apple_intent_library`.
http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "5620fcaf237444ba088b2c1669c81ff14a7746357487d7a58ea7d90deb21a82d",
    strip_prefix = "rules_apple-22c292e70cf7169038de9ef25d4b1b25f411c89f",
    url = "https://github.com/bazelbuild/rules_apple/archive/22c292e70cf7169038de9ef25d4b1b25f411c89f.tar.gz",
)

load("//xcodeproj:repositories.bzl", "xcodeproj_rules_dependencies")

xcodeproj_rules_dependencies(use_dev_patches = True)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

# External repos for examples

local_repository(
    name = "examples_cc_external",
    path = "examples/cc/external",
)

new_local_repository(
    name = "examples_command_line_external",
    build_file = "examples/command_line/external/BUILD.tpl",
    path = "examples/command_line/external",
)

load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "provisioning_profile_repository",
)

provisioning_profile_repository(
    name = "local_provisioning_profiles",
)

http_archive(
    name = "com_google_google_maps",
    build_file_content = """\
load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import",
)

apple_static_xcframework_import(
    name = "GoogleMaps",
    sdk_frameworks = ["SystemConfiguration"],
    xcframework_imports = glob(
        ["GoogleMaps.xcframework/**"],
        exclude = ["**/.*"],
    ),
    visibility = ["//visibility:public"],
    deps = [":GoogleMapsCore"],
)

apple_static_xcframework_import(
    name = "GoogleMapsBase",
    sdk_dylibs = [
        "c++",
        "z",
    ],
    sdk_frameworks = [
        "CoreLocation",
        "CoreTelephony",
    ],
    xcframework_imports = glob(
        ["GoogleMapsBase.xcframework/**"],
        exclude = ["**/.*"],
    ),
)

apple_static_xcframework_import(
    name = "GoogleMapsCore",
    xcframework_imports = glob(
        ["GoogleMapsCore.xcframework/**"],
        exclude = ["**/.*"],
    ),
    deps = [":GoogleMapsBase"],
)
""",
    sha256 = "2308155fc29655ee3722e1829bd2c1b09f457b7140bc65cad6116dd8a4ca8bff",
    strip_prefix = "GoogleMaps-6.2.1-beta",
    url = "https://dl.google.com/geosdk/GoogleMaps-6.2.1-beta.tar.gz",
)

http_archive(
    name = "com_github_krzyzanowskim_cryptoswift",
    build_file_content = """\
load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_dynamic_xcframework_import",
)

apple_dynamic_xcframework_import(
    name = "CryptoSwift",
    xcframework_imports = glob(
        ["CryptoSwift.xcframework/**"],
        exclude = ["**/.*"],
    ),
    visibility = ["//visibility:public"],
)
""",
    sha256 = "b251155dce1e5f705f40bf1d531d56851b90f1907a8ff07d0e0c471f12316515",
    url = "https://github.com/krzyzanowskim/CryptoSwift/releases/download/1.5.1/CryptoSwift.xcframework.zip",
)

# Setup Swift Custom Dump test dependency

http_archive(
    name = "com_github_pointfreeco_xctest_dynamic_overlay",
    build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "XCTestDynamicOverlay",
    module_name = "XCTestDynamicOverlay",
    srcs = glob(["Sources/XCTestDynamicOverlay/**/*.swift"]),
    visibility = ["//visibility:public"],
)
""",
    sha256 = "97169124feb98b409f5b890bd95bb147c2fba0dba3098f9bf24c539270ee9601",
    strip_prefix = "xctest-dynamic-overlay-0.2.1",
    url = "https://github.com/pointfreeco/xctest-dynamic-overlay/archive/refs/tags/0.2.1.tar.gz",
)

http_archive(
    name = "com_github_pointfreeco_swift_custom_dump",
    build_file_content = """\
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CustomDump",
    module_name = "CustomDump",
    srcs = glob(["Sources/CustomDump/**/*.swift"]),
    deps = ["@com_github_pointfreeco_xctest_dynamic_overlay//:XCTestDynamicOverlay"],
    visibility = ["//visibility:public"],
)
""",
    patches = [
        # Custom for our tests
        "//third_party/com_github_pointfreeco_swift_custom_dump:type_name.patch",
    ],
    sha256 = "a45e8f275794960651043623e23abb8365f0455b4ad5976bc56a4fa00c5efb31",
    strip_prefix = "swift-custom-dump-0.5.0",
    url = "https://github.com/pointfreeco/swift-custom-dump/archive/refs/tags/0.5.0.tar.gz",
)

# Setup the Skylib dependency, this is required to use the Starlark unittest
# framework. Since this is only used for rules_xcodeproj's tests, we configure
# it here in the WORKSPACE file. This also can't be added to
# `xcodeproj_rules_dependencies` since we need to load the bzl file, so if we
# wanted to load it inside of a macro, it would need to be in a different file
# to begin with.
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

# Buildifier

http_archive(
    name = "buildifier_prebuilt",
    sha256 = "0450069a99db3d414eff738dd8ad4c0969928af13dc8614adbd1c603a835caad",
    strip_prefix = "buildifier-prebuilt-0.4.0",
    urls = [
        "http://github.com/keith/buildifier-prebuilt/archive/0.4.0.tar.gz",
    ],
)

load("@buildifier_prebuilt//:deps.bzl", "buildifier_prebuilt_deps")

buildifier_prebuilt_deps()

load("@buildifier_prebuilt//:defs.bzl", "buildifier_prebuilt_register_toolchains")

buildifier_prebuilt_register_toolchains()
