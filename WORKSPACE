workspace(name = "com_github_buildbuddy_io_rules_xcodeproj")

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

local_repository(
    name = "examples_command_line_external",
    path = "examples/command_line/external",
)

load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "provisioning_profile_repository",
)

provisioning_profile_repository(
    name = "local_provisioning_profiles",
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

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
    sha256 = "2e55a6c40ddf4d0401514ef3fa29eb07c395d2f4a1844c6c22cdc2c54dcb71f9",
    strip_prefix = "swift-custom-dump-15fae98653ab3573b458bdb416cbba06e95348a4",
    url = "https://github.com/pointfreeco/swift-custom-dump/archive/15fae98653ab3573b458bdb416cbba06e95348a4.tar.gz",
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

# Bazel Integration Test

http_archive(
    name = "contrib_rules_bazel_integration_test",
    sha256 = "24e5e8f388bec2da0975cfda6073ed0174a4f62cb874b5dc8037c98faa6acdfd",
    strip_prefix = "rules_bazel_integration_test-0.7.0",
    urls = [
        "http://github.com/bazel-contrib/rules_bazel_integration_test/archive/v0.7.0.tar.gz",
    ],
)

load("@contrib_rules_bazel_integration_test//bazel_integration_test:deps.bzl", "bazel_integration_test_rules_dependencies")

bazel_integration_test_rules_dependencies()

load("@cgrindel_bazel_starlib//:deps.bzl", "bazel_starlib_dependencies")

bazel_starlib_dependencies()

# Bazel Binaries for Bazel Integration Tests

load("@contrib_rules_bazel_integration_test//bazel_integration_test:defs.bzl", "bazel_binaries")
load("//:bazel_versions.bzl", "SUPPORTED_BAZEL_VERSIONS")

bazel_binaries(versions = SUPPORTED_BAZEL_VERSIONS)
