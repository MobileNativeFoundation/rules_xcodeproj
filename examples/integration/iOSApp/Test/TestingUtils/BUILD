load("@build_bazel_rules_apple//apple:macos.bzl", "macos_build_test")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

macos_build_test(
    name = "macos_TestingUtils",
    minimum_os_version = "12.0",
    tags = ["manual"],
    targets = [":TestingUtils"],
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)

swift_library(
    name = "TestingUtils",
    testonly = True,
    srcs = [":gen_TestingUtils.swift"],
    defines = ["AWESOME"],
    generated_header_name = "SwiftAPI/TestingUtils-Swift.h",
    generates_header = True,
    module_name = "TestingUtils",
    tags = ["manual"],
    visibility = ["//iOSApp/Test:__subpackages__"],
)

genrule(
    name = "gen_Answer.swift",
    srcs = ["Answer.swift.stencil"],
    outs = ["Answer.swift"],
    cmd = """sed 's/{{ answer }}/2147483647/' $< > $@""",
)

genrule(
    name = "gen_Greeting.swift",
    srcs = ["Greeting.swift.stencil"],
    outs = ["Greeting.swift"],
    cmd = """sed 's/{{ greeting }}/Hello, world?/' $< > $@""",
)

genrule(
    name = "gen_TestingUtils.swift",
    srcs = [
        ":gen_Greeting.swift",
        ":gen_Answer.swift",
    ],
    outs = ["TestingUtils.swift"],
    cmd = "./$(location merger) $@ $(SRCS)",
    tools = [":merger"],
)

sh_binary(
    name = "merger",
    srcs = ["merge.sh"],
)
