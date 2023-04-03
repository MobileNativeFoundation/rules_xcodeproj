load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

rules_ios_apple_framework(
    name = "TestingUtils",
    testonly = True,
    srcs = [":gen_TestingUtils.swift"],
    defines = ["AWESOME"],
    module_name = "TestingUtils",
    platforms = {
        "ios": "15.0",
    },
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
