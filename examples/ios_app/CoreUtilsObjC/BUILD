objc_library(
    name = "CoreUtilsObjC",
    srcs = glob(
        [
            "**/*.m",
            "**/*.mm",
            # Headers included here on purpose, to test `hdrs` collection logic
            "**/*.h",
        ],
        allow_empty = True,
    ),
    hdrs = glob(["**/*.h"]),
    includes = [""],
    module_name = "CoreUtils",
    pch = "CoreUtils/CoreUtils.pch",
    sdk_dylibs = ["c++"],
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = [
        "//third_party:ExampleFramework",
        "@examples_ios_app_external//:ExternalFramework",
    ],
)
