objc_library(
    name = "Utils",
    srcs = glob(
        ["**/*.m"],
        # Headers included here on purpose, to test `hdrs` collection logic
        ["**/*.h"],
    ),
    hdrs = glob(["**/*.h"]),
    module_name = "Utils",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = ["//CoreUtilsObjC"],
)
