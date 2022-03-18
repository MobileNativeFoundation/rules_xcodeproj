objc_library(
    name = "CoreUtilsObjC",
    srcs = glob(
        ["**/*.m"],
        # Headers included here on purpose, to test `hdrs` collection logic
        ["**/*.h"],
    ),
    hdrs = glob(["**/*.h"]),
    includes = [""],
    module_name = "CoreUtils",
    visibility = ["//visibility:public"],
)
