load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load(":dep_resources_collector.bzl", "dep_resources_collector")
load("//iOSApp/Source:file_generation.bzl", "generated_file")

GENERATED_CORE_DATA_VERSION_FILE = "GeneratedModel.xcdatamodeld/.xccurrentversion"
GENERATED_CORE_DATA_CONTENTS_FILE = "GeneratedModel.xcdatamodeld/GeneratedModel.xcdatamodel/contents"

generated_file(
    name = "GeneratedCoreDataVersion",
    source_file = GENERATED_CORE_DATA_VERSION_FILE,
    output_name = "GeneratedModel.xcdatamodeld/.xccurrentversion",
)

generated_file(
    name = "GeneratedCoreDataContents",
    source_file = GENERATED_CORE_DATA_CONTENTS_FILE,
    output_name = "GeneratedModel.xcdatamodeld/GeneratedModel.xcdatamodel/contents",
)

apple_resource_bundle(
    name = "ExampleResources",
    bundle_id = "com.example.resources",
    infoplists = ["Info.plist"],
    resources = glob(["Assets.xcassets/**"]) + [
        ":deps_txt",
        "//iOSApp/Resources/ExampleNestedResources",
        ":GeneratedCoreDataContents",
        ":GeneratedCoreDataVersion",
    ],
    structured_resources = ["nested/hello.txt"],
    visibility = ["//iOSApp:__subpackages__"],
)

dep_resources_collector(
    name = "deps_txt",
    deps = ["//iOSApp/Source/Utils"],
)

filegroup(
    name = "exported_resources",
    srcs = glob(["Assets.xcassets/**"]),
    visibility = ["//iOSApp:__subpackages__"],
)
