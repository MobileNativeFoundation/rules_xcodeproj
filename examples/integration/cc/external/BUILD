load(":local_includes.bzl", "local_includes")

cc_library(
    name = "cc_external_lib_impl",
    srcs = [
        "lib.c",
        "private/private.inc",
    ],
    # Simulating a "local_includes"
    copts = local_includes("private"),
    local_defines = ["EXTERNAL_SECRET_3=\\\"Goodbye\\\""],
)

cc_library(
    name = "cc_external_lib_defines",
    defines = ["EXTERNAL_SECRET_2=\\\"World?\\\""],
    deps = [":cc_external_lib_impl"],
)

cc_library(
    name = "cc_external_lib_headers",
    hdrs = ["lib.h"],
    deps = [":cc_external_lib_defines"],
)

alias(
    name = "lib",
    actual = ":cc_external_lib_headers",
    visibility = ["//visibility:public"],
)
