cc_library(
    name = "cc_lib_impl",
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
    name = "cc_lib2",
    actual = "cc_lib_impl",
    visibility = ["//visibility:public"],
)
