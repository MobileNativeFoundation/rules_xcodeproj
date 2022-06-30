load("@examples_cc_external//:local_includes.bzl", "local_includes")

cc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
        "private/private.h",
    ],
    # Simulating a "local_includes"
    copts = local_includes("private"),
    local_defines = ["SECRET_3=\\\"Hello\\\""],
    alwayslink = True,
)

cc_library(
    name = "lib_defines",
    defines = ["SECRET_2=\\\"World!\\\""],
    deps = [":lib_impl"],
)

cc_library(
    name = "lib_headers",
    hdrs = ["lib.h"],
    deps = [":lib_defines"],
)

alias(
    name = "lib",
    actual = ":lib_headers",
    visibility = ["//visibility:public"],
)
