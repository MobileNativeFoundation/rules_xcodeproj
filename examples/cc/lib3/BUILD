cc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
    ],
    linkopts = [
        "-Wl,-exported_symbol,_lib3Version",
    ],
    deps = [
        ":lib_headers",
    ],
    alwayslink = True,
)

cc_library(
    name = "lib_headers",
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
        ":lib_impl",
    ],
)

cc_library(
    name = "lib3",
    srcs = [
        "libfoo.dylib",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":lib_headers",
    ],
)
