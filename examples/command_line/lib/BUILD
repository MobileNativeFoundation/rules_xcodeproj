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
        "lib.c",
        "private.h",
    ],
    deps = [":lib_defines"],
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
