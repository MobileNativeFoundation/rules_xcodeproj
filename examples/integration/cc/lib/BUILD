cc_library(
    name = "cc_lib_defines",
    srcs = [
        "defines.c",
    ],
    defines = ["SECRET_2=\\\"World!\\\""],
    implementation_deps = ["//cc/lib/impl:cc_lib_impl"],
)

cc_library(
    name = "cc_lib_headers",
    hdrs = ["lib.h"],
    deps = [":cc_lib_defines"],
)

alias(
    name = "cc_lib",
    actual = ":cc_lib_headers",
    visibility = ["//visibility:public"],
)
