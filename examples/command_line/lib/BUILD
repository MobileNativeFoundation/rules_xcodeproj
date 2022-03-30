objc_library(
    name = "lib_defines",
    defines = [
        "SECRET_3=\\\"Hello\\\"",
        "SECRET_2=\\\"World!\\\"",
    ],
)

objc_library(
    name = "lib_impl",
    srcs = [
        "lib.m",
        "private.h",
    ],
    tags = ["manual"],
    deps = [
        ":lib_defines",
    ],
)

objc_library(
    name = "lib_headers",
    hdrs = ["dir with space/lib.h"],
    includes = ["dir with space"],
    deps = [":lib_impl"],
)

alias(
    name = "lib",
    actual = ":lib_headers",
    visibility = ["//visibility:public"],
)
