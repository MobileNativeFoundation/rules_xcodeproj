py_library(
    name = "cc_compiler_params_processor_library",
    srcs = ["cc_compiler_params_processor.py"],
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
)

py_binary(
    name = "cc_compiler_params_processor",
    srcs = ["cc_compiler_params_processor.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
    deps = [":cc_compiler_params_processor_library"],
)

py_test(
    name = "cc_compiler_params_processor_tests",
    srcs = ["cc_compiler_params_processor_tests.py"],
    deps = [
        ":cc_compiler_params_processor_library",
        "//:py_init_shim",
    ],
)

py_binary(
    name = "link_params_processor",
    srcs = ["link_params_processor.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
)

py_binary(
    name = "swift_debug_settings_processor",
    srcs = ["swift_debug_settings_processor.py"],
    python_version = "PY3",
    srcs_version = "PY3",
    # TODO: Restrict visibility
    visibility = ["//visibility:public"],
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
        ],
    ),
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)
