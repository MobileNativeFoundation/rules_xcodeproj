# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:custom_toolchain.bzl", "custom_toolchain")

# Example swiftc override for testing
filegroup(
    name = "test_swiftc",
    srcs = ["test_swiftc.sh"],
    visibility = ["//visibility:public"],
)

# Test target for custom_toolchain
custom_toolchain(
    name = "test_toolchain",
    overrides = {
        # Key is a label target, value is the tool name
        ":test_swiftc": "swiftc",
    },
    toolchain_name = "TestCustomToolchain",
)

# Add a simple test rule that depends on the toolchain
sh_test(
    name = "custom_toolchain_test",
    srcs = ["custom_toolchain_test.sh"],
    args = ["$(location :test_toolchain)"],
    data = [":test_toolchain"],
)
