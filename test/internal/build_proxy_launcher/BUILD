load("@rules_shell//shell:sh_test.bzl", "sh_test")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:xcodeproj_runner.bzl", "xcodeproj_runner")

# Analysis coverage for the configured, non-exec-transitioned file contract.
xcodeproj_runner(
    name = "configured_runner",
    testonly = True,
    bazel_env = {},
    bazel_path = "bazel",
    build_proxy = "fake_build_proxy.sh",
    build_proxy_sha256 = "0000000000000000000000000000000000000000000000000000000000000000",
    config = "rules_xcodeproj",
    focused_labels = [],
    generation_shard_count = 1,
    generator_bazel_env = {},
    import_index_build_indexstores = True,
    install_directory = "test/internal/build_proxy_launcher",
    ios_device_cpus = "arm64",
    owned_extra_files = {},
    project_name = "ConfiguredProxy",
    project_options = {},
    scheme_autogeneration_config = {},
    storekit_configurations_map = {},
    tags = ["manual"],
    top_level_device_targets = [],
    top_level_simulator_targets = [],
    tvos_device_cpus = "arm64",
    unfocused_labels = [],
    unowned_extra_files = [],
    visionos_device_cpus = "arm64",
    visionos_simulator_cpus = "sim_arm64",
    watchos_device_cpus = "arm64_32",
    xcode_configuration_flags = [],
    xcode_configuration_map = {"Debug": ["Debug"]},
    xcode_configurations = "{'Debug': {}}",
)

sh_test(
    name = "build_proxy_launcher_tests",
    size = "small",
    srcs = ["build_proxy_launcher_tests.sh"],
    data = [
        ":configured_runner",
        "//xcodeproj/internal/templates:build_proxy_launcher.sh",
        "//xcodeproj/internal/templates:install_build_proxy.sh",
    ],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
