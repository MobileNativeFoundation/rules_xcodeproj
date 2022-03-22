cc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
    ],
    hdrs = [
        "lib.h",
    ],
)

alias(
    name = "lib2",
    actual = "lib_impl",
    visibility = ["//visibility:public"],
)
