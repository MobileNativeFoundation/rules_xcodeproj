objc_library(
    name = "Utils",
    srcs = glob(
        ["**/*.m"],
        # Headers included here on purpose, to test `hdrs` collection logic
        ["**/*.h"],
    ),
    hdrs = glob(["**/*.h"]),
    data = ["@examples_ios_app_external//:ExternalImportedBundle"],
    module_name = "Utils",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = ["//CoreUtilsObjC"],
)
