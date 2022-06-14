load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_application")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "Example.library",
    srcs = glob(["**/*.swift"]),
    module_name = "Example",
    tags = ["manual"],
    visibility = ["//visibility:public"],
)

tvos_application(
    name = "Example",
    bundle_id = "io.buildbuddy.example",
    bundle_name = "Example",
    entitlements = ":entitlements",
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    visibility = ["//visibility:public"],
    deps = [":Example.library"],
)

genrule(
    name = "entitlements",
    outs = ["app.entitlements"],
    cmd = """\
cat > $@ <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
</dict>
</plist>
EOF
""",
)
