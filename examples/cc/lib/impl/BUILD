load("@examples_cc_external//:local_includes.bzl", "local_includes")

cc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
        "private/private.h",
    ],
    hdrs = [
        "impl.h",
    ],
    # Simulating a "local_includes"
    copts = local_includes("private"),
    defines = ["IMPL_DEFINE=\\\"Implementation\\\""],
    includes = ["."],
    local_defines = ["SECRET_3=\\\"Hello\\\""],
    visibility = ["//lib:__pkg__"],
    alwayslink = True,
)
