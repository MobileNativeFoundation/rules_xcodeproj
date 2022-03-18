load("@rules_cc//cc:defs.bzl", "objc_library")

objc_library(
    name = "Utils",
    srcs = glob(
        ["**/*.m"],
        # Headers included here on purpose, to test `hdrs` collection logic
        ["**/*.h"],
    ),
    hdrs = glob(["**/*.h"]),
    enable_modules = True,
    module_name = "Utils",
    visibility = ["//visibility:public"],
)
