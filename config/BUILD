load(":allow_multiple_flag.bzl", "allow_multiple_flag")

# load("@bazel_skylib//rules:common_settings.bzl", "string_list_flag")
# load("@bazel_skylib//rules:common_settings.bzl", "string_flag")

# string_flag(
#     name = "integration_test_config",
#     build_setting_default = "",
#     values = [
#         "",
#         "cache",
#         "workflows",
#     ],
#     visibility = ["//:__subpackages__"],
# )

# string_list_flag(
#     name = "integration_test_config",
#     visibility = ["//:__subpackages__"],
# )

allow_multiple_flag(
    name = "integration_test_config",
    build_setting_default = "",
    visibility = ["//:__subpackages__"],
)
