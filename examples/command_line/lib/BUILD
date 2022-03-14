objc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
        "private.h",
    ],
)

objc_library(
    name = "lib_headers",
    hdrs = ["dir with space/lib.h"],
    enable_modules = True,
    includes = ["dir with space"],
    deps = [":lib_impl"],
)

alias(
    name = "lib",
    actual = ":lib_headers",
    visibility = ["//visibility:public"],
)
