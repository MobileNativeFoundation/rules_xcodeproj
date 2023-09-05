cc_library(
    name = "cc_lib_impl",
    srcs = [
        "lib.c",
    ],
    linkopts = [
        "-Wl,-exported_symbol,_lib3Version",
    ],
    deps = [
        ":cc_lib_headers",
    ],
    alwayslink = True,
)

cc_library(
    name = "cc_lib_headers",
    hdrs = ["includes/lib3.h"],
    include_prefix = "lib3",
    includes = ["includes"],
    strip_include_prefix = "includes",
)

# for generating 'libfoo.dylib'
cc_binary(
    name = "libfoo.dylib",
    linkshared = True,
    linkstatic = True,
    deps = [
        ":cc_lib_impl",
    ],
)

cc_library(
    name = "cc_lib3",
    srcs = [
        "libfoo.dylib",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":cc_lib_headers",
    ],
)
