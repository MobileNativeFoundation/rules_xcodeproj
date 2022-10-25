_BASE_FILES = [
    "bazel_build.sh",
    "calculate_output_groups.py",
    "create_lldbinit.sh",
    "generate_bazel_dependencies.sh",
    "import_indexstores.sh",
    "process_bazel_build_log.py",
]

filegroup(
    name = "base_integration_files",
    srcs = _BASE_FILES,
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

filegroup(
    name = "bazel_integration_files",
    srcs = [
        ":swiftc",
        ":rsync_excludes",
    ] + glob(
        ["**/*"],
        exclude = _BASE_FILES + [
            "BUILD",
        ],
    ),
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

genrule(
    name = "rsync_excludes",
    outs = ["exclude.rsynclist"],
    cmd = """\
extensions=(
  app
  appex
  xctest
)
folders=(
  'Contents/Frameworks'
  'Frameworks'
)
frameworks=(
  'libclang_rt.asan*.dylib'
  'libclang_rt.tsan*.dylib'
  'libclang_rt.ubsan*.dylib'
  'libXCTestBundleInject.dylib'
  'libXCTestSwiftSupport.dylib'
  'XCTAutomationSupport.framework'
  'XCTest.framework'
  'XCTestCore.framework'
  'XCTestSupport.framework'
  'XCUIAutomation.framework'
  'XCUnit.framework'
)

for extension in "$${extensions[@]}"; do
  for folder in "$${folders[@]}"; do
    for framework in "$${frameworks[@]}"; do
      echo "/*.$$extension/$$folder/$$framework" >> $@
    done
  done
done
echo '/*.app/PlugIns/*.xctest' >> $@
echo '/*.appex/PlugIns/*.xctest' >> $@
""",
    tags = ["manual"],
)

genrule(
    name = "swiftc_stub",
    srcs = ["//tools/swiftc_stub:universal_swiftc_stub"],
    outs = ["swiftc"],
    # Make the swiftc_stub have the right name
    cmd = "cp -c $< $@",
    message = "Renaming swiftc stub",
    tags = [
        "manual",
        "no-sandbox",
    ],
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
