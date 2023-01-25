cc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
    ],
    hdrs = [
        "includes/lib2.h",
    ],
    include_prefix = "lib2_prefix",
    includes = ["includes"],
    strip_include_prefix = "includes",
)

alias(
    name = "lib2",
    actual = "lib_impl",
    visibility = ["//visibility:public"],
)
