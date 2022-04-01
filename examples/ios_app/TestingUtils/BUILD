load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TestingUtils",
    testonly = True,
    srcs = [":gen_TestingUtils.swift"],
    defines = ["AWESOME"],
    generated_header_name = "SwiftAPI/TestingUtils-Swift.h",
    generates_header = True,
    module_name = "TestingUtils",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

genrule(
    name = "gen_Answer.swift",
    srcs = ["Answer.swift.stencil"],
    outs = ["Answer.swift"],
    cmd = """sed 's/{{ answer }}/42/' $< > $@""",
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
