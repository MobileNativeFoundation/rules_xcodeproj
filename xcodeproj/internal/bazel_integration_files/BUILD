load("@rules_python//python:defs.bzl", "py_library", "py_test")

_BASE_FILES = [
    "calculate_output_groups.py",
    "copy_dsyms.sh",
    "create_lldbinit.sh",
    ":renamed_import_indexstores",
    "process_bazel_build_log.py",
]

_TEST_FILES = [
    "process_bazel_build_log_tests.py",
    "write_build_proxy_invocation_receipt_tests.py",
]

py_library(
    name = "write_build_proxy_invocation_receipt_lib",
    srcs = ["write_build_proxy_invocation_receipt.py"],
)

py_test(
    name = "write_build_proxy_invocation_receipt_tests",
    srcs = ["write_build_proxy_invocation_receipt_tests.py"],
    deps = [":write_build_proxy_invocation_receipt_lib"],
)

py_test(
    name = "process_bazel_build_log_tests",
    srcs = [
        "process_bazel_build_log.py",
        "process_bazel_build_log_tests.py",
    ],
    main = "process_bazel_build_log_tests.py",
)

filegroup(
    name = "bazel_integration_files",
    srcs = _BASE_FILES + [
        ":renamed_rsync",
        ":renamed_swiftc_stub",
        ":rsync_excludes",
    ] + glob(
        ["**/*"],
        exclude = _BASE_FILES + _TEST_FILES + [
            "**/*.bzl",
            "BUILD",
        ],
    ),
    # This is made public for internal use only
    visibility = ["//visibility:public"],
)

genrule(
    name = "rsync_excludes",
    outs = [
        "app.exclude.rsynclist",
        "watchos2_app.exclude.rsynclist",
        "framework.exclude.rsynclist",
        "appex.exclude.rsynclist",
        "xctest.exclude.rsynclist",
    ],
    cmd = """\
readonly an_output="$(execpath app.exclude.rsynclist)"
cd "$${an_output%/*}"

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
  'Testing.framework',
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
      echo "/*.$$extension/$$folder/$$framework" >> "$$extension.exclude.rsynclist"
      if [[ "$$extension" == "app" ]]; then
        echo "/*.$$extension/$$folder/$$framework" >> "watchos2_app.exclude.rsynclist"
      fi
    done
  done
done

# watchOS 2 apps have their application extension embedded
echo '/*.app/PlugIns/***' >> "watchos2_app.exclude.rsynclist"
echo '/*.app/_WatchKitStub/***' >> "watchos2_app.exclude.rsynclist"

# Tests embedded in test hosts
echo '/*.app/PlugIns/*.xctest' >> "app.exclude.rsynclist"
echo '/*.app/PlugIns/*.xctest' >> "watchos2_app.exclude.rsynclist"
echo '/*.appex/PlugIns/*.xctest' >> "appex.exclude.rsynclist"

echo '/*.framework/Modules/***' >> "framework.exclude.rsynclist"
echo '/*.framework/SwiftUIPreviewsFrameworks/***' >> "framework.exclude.rsynclist"
""",
    tags = ["manual"],
)

genrule(
    name = "renamed_import_indexstores",
    srcs = ["//tools/import_indexstores:universal_import_indexstores"],
    outs = ["import_indexstores"],
    # Make `import_indexstores` have the right name
    cmd = """\
readonly output="$@"
if [[ $$(stat -f '%d' "$<") == $$(stat -f '%d' "$${output%/*}") ]]; then
  cp -c "$<" "$@"
else
  cp "$<" "$@"
fi
""",
    message = "Renaming import_indexstores",
    tags = [
        "manual",
        "no-sandbox",
    ],
)

genrule(
    name = "renamed_swiftc_stub",
    srcs = ["//tools/swiftc_stub:universal_swiftc_stub"],
    outs = ["swiftc"],
    # Make `swiftc_stub` have the right name
    cmd = """\
readonly output="$@"
if [[ $$(stat -f '%d' "$<") == $$(stat -f '%d' "$${output%/*}") ]]; then
  cp -c "$<" "$@"
else
  cp "$<" "$@"
fi
""",
    message = "Renaming swiftc_stub",
    tags = [
        "manual",
        "no-sandbox",
    ],
)

genrule(
    name = "renamed_rsync",
    srcs = ["@rsync"],
    outs = ["rsync"],
    # Make `rsync` have the right name
    cmd = """\
readonly output="$@"
if [[ $$(stat -f '%d' "$<") == $$(stat -f '%d' "$${output%/*}") ]]; then
  cp -c "$<" "$@"
else
  cp "$<" "$@"
fi
""",
    message = "Renaming rsync",
    tags = [
        "manual",
        "no-sandbox",
    ],
    visibility = ["//visibility:public"],
)

# Release

filegroup(
    name = "release_files",
    srcs = glob(
        ["**"],
        exclude = [
            "**/.*",
        ],
    ),
    tags = ["manual"],
    visibility = ["//:__subpackages__"],
)
