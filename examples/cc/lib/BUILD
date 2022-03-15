cc_library(
    name = "actual_lib",
    srcs = [
        "lib.c",
        "private.h",
    ],
)

cc_library(
    name = "headers_only",
    hdrs = ["lib.h"],
    deps = [":actual_lib"],
)

alias(
    name = "lib",
    actual = ":headers_only",
    visibility = ["//visibility:public"],
)
