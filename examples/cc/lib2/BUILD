cc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
    ],
    hdrs = [
        "includes/lib.h",
    ],
    includes = ["includes"],
)

alias(
    name = "lib2",
    actual = "lib_impl",
    visibility = ["//visibility:public"],
)
