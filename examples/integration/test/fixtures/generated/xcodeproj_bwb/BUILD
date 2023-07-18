load(
    ":defs.bzl",
    "BAZEL_ENV",
    "BAZEL_PATH",
    "WORKSPACE_DIRECTORY",
    "xcodeproj",
)

# DO NOT INVOKE THIS TARGET YOURSELF.
#
# This target is generated and invoked by `xcodeproj_runner`.
xcodeproj(
    name = "xcodeproj_bwb",
    testonly = True,
    adjust_schemes_for_swiftui_previews = True,
    bazel_env = BAZEL_ENV,
    bazel_path = BAZEL_PATH,
    build_mode = "bazel",
    colorize = True,
    config = "rules_xcodeproj_integration",
    default_xcode_configuration = "Debug",
    fail_for_invalid_extra_files_targets = True,
    focused_targets = [],
    install_path = "test/fixtures/bwb.xcodeproj",
    ios_device_cpus = "arm64",
    ios_simulator_cpus = "",
    minimum_xcode_version = "13.0",
    owned_extra_files = {"@//iOSApp:ownership.yaml": "@//iOSApp/Source:iOSApp", "@//Lib:README.md": "@//Lib:Lib"},
    post_build = """""",
    pre_build = """set -euo pipefail

if [[ "$ACTION" == "build" ]]; then
  cd "$SRCROOT"
  echo "Hello from pre-build!"
fi""",
    project_name = "bwb",
    project_options = {"development_region": "es", "indent_width": "3", "organization_name": "BB", "tab_width": "2", "uses_tabs": "1"},
    runner_build_file = "test/fixtures/BUILD",
    runner_label = "//test/fixtures:xcodeproj_bwb",
    scheme_autogeneration_mode = "all",
    schemes_json = ":custom_xcode_schemes.json",
    tags = ["manual"],
    top_level_device_targets = ["@//CommandLine/CommandLineTool:CommandLineTool", "@//CommandLine/CommandLineTool:UniversalCommandLineTool", "@//CommandLine/Tests:BasicTests", "@//CommandLine/Tests:CommandLineToolTests", "@//iOSApp:iOSApp", "@//Lib:ios_Lib", "@//Lib/dist/dynamic:iOS", "@//Lib/dist/dynamic:tvOS", "@//Lib/dist/dynamic:watchOS", "@//tvOSApp:tvOSApp"],
    top_level_simulator_targets = ["@//iOSApp:iOSApp", "@//Lib:ios_Lib", "@//Lib/dist/dynamic:iOS", "@//Lib/dist/dynamic:tvOS", "@//Lib/dist/dynamic:watchOS", "@//tvOSApp:tvOSApp", "@//Bundle:Bundle", "@//iOSApp/Test/UITests:iOSAppUITests", "@//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests", "@//iOSApp/Test/TestingUtils:macos_TestingUtils", "@//iMessageApp:iMessageApp", "@//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests", "@//macOSApp/Source:macOSApp", "@//macOSApp/Test/UITests:macOSAppUITests", "@//tvOSApp/Test/UITests:tvOSAppUITests", "@//tvOSApp/Test/UnitTests:tvOSAppUnitTests", "@//watchOSApp/Test/UITests:watchOSAppUITests", "@//watchOSAppExtension/Test/UnitTests:watchOSAppExtensionUnitTests", "@//iOSApp/Test:iOSAppTestSuite", "@//iOSApp/Test/UITests:iOSAppUITestSuite", "@//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTestSuite", "@//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTestSuite"],
    tvos_device_cpus = "arm64",
    tvos_simulator_cpus = "",
    unfocused_targets = ["@//Lib:LibFramework.iOS"],
    unowned_extra_files = ["@//:README.md"],
    visibility = ["//test:__subpackages__"],
    watchos_device_cpus = "arm64_32",
    watchos_simulator_cpus = "",
    workspace_directory = WORKSPACE_DIRECTORY,
    xcode_configuration_map = {"AppStore": ["AppStore"], "Debug": ["Debug"]},
)
