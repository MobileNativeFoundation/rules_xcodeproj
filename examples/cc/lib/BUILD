cc_library(
    name = "lib_defines",
    srcs = [
        "defines.c",
    ],
    defines = ["SECRET_2=\\\"World!\\\""],
    implementation_deps = ["//lib/impl:lib_impl"],
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
