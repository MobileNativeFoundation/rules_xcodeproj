cc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
        "private.h",
    ],
    local_defines = ["SECRET_3=\\\"Hello\\\""],
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
