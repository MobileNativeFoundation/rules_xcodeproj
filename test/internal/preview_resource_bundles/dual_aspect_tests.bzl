"""Regression test for rules_apple and rules_xcodeproj resource aspects."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleResourceInfo",
)
load(
    "@build_bazel_rules_apple//apple/internal/aspects:resource_aspect.bzl",
    "apple_resource_aspect",
)
load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")
load("//xcodeproj:xcodeprojinfo.bzl", "XcodeProjInfo")
load("//xcodeproj/internal/files:input_files.bzl", "input_files")
load(
    "//xcodeproj/internal:preview_resource_bundles.bzl",
    "XcodeProjPreviewResourceInfo",
)
load(
    "//xcodeproj/internal:xcodeproj_aspect.bzl",
    "xcodeproj_aspect",
)

_GENERATOR_NAME = "dual_aspect_test"

_preview_aspect = aspect(
    implementation = xcodeproj_aspect.impl,
    attr_aspects = ["*"],
    attrs = xcodeproj_aspect.attrs(
        focused_labels = [
            "//test/internal/preview_resource_bundles:RawResources",
            "//test/internal/preview_resource_bundles:ResourceLibrary",
            "//test/internal/preview_resource_bundles:ResourceAppLibrary",
            "//test/internal/preview_resource_bundles:ResourceApp",
            "//test/internal/preview_resource_bundles:ResourceFramework",
        ],
        generator_name = _GENERATOR_NAME,
        unfocused_labels = [],
    ),
    fragments = ["apple", "cpp", "objc"],
    toolchains = use_cc_toolchain(),
)

_second_preview_aspect = aspect(
    implementation = xcodeproj_aspect.impl,
    attr_aspects = ["*"],
    attrs = xcodeproj_aspect.attrs(
        focused_labels = [
            "//test/internal/preview_resource_bundles:RawResources",
        ],
        generator_name = "second_generator_test",
        unfocused_labels = [],
    ),
    fragments = ["apple", "cpp", "objc"],
    toolchains = use_cc_toolchain(),
)

def _processed_files(resource_info):
    return [
        file
        for _, _, files in resource_info.processed
        for file in files.to_list()
        if not file.is_source
    ]

def _dual_aspect_resource_bundle_test_impl(ctx):
    target = ctx.attr.target
    if AppleResourceInfo not in target:
        fail("Official apple_resource_aspect did not provide AppleResourceInfo")
    if XcodeProjPreviewResourceInfo not in target:
        fail("Xcode Preview aspect did not provide XcodeProjPreviewResourceInfo")
    if XcodeProjInfo not in target:
        fail("Xcode Preview aspect did not provide XcodeProjInfo")

    official_files = _processed_files(target[AppleResourceInfo])
    preview_files = _processed_files(
        target[XcodeProjPreviewResourceInfo].resource_info,
    )
    if not official_files or not preview_files:
        fail("Both aspects must register processed resource outputs")

    official_paths = {file.path: None for file in official_files}
    preview_paths = {file.path: None for file in preview_files}
    duplicate_paths = [
        path
        for path in official_paths
        if path in preview_paths
    ]
    if duplicate_paths:
        fail("Resource aspects declared duplicate outputs: {}".format(
            duplicate_paths,
        ))

    discriminator = "-intermediates-rules_xcodeproj_{}/".format(
        _GENERATOR_NAME,
    )
    if not all([discriminator in file.path for file in preview_files]):
        fail("Preview resource outputs are not generator-namespaced: {}".format(
            preview_paths.keys(),
        ))

    preview_bundles = [
        bundle
        for bundle in target[XcodeProjInfo].inputs._preview_resource_bundles.to_list()
        if bundle.name == "RawResources"
    ]
    if len(preview_bundles) != 1:
        fail("Expected one materialized Preview resource bundle, got {}".format(
            len(preview_bundles),
        ))
    bundle = preview_bundles[0].file

    verified = ctx.actions.declare_file(
        "dual_aspect_resource_bundle.verified",
    )
    ctx.actions.run_shell(
        arguments = [bundle.path, verified.path] + [
            file.path
            for file in official_files
        ],
        command = """\
set -euo pipefail

readonly bundle="$1"
readonly output="$2"
shift 2

test -f "$bundle/Info.plist"
test -f "$bundle/Assets.car"
test -f "$bundle/en.lproj/Localizable.strings"
test "$(cat "$bundle/NestedResources.bundle/value.txt")" = nested-resource-value
test -f "$bundle/MetadataOnlyResources.bundle/Info.plist"
test -z "$(find "$bundle/MetadataOnlyResources.bundle" -mindepth 1 ! -name Info.plist -print -quit)"
test ! -e "$bundle/Colors.xcassets"
test "$(plutil -extract CFBundleIdentifier raw "$bundle/Info.plist")" = \
  com.example.rules-xcodeproj.dual-aspect
test "$(plutil -extract CFBundleName raw "$bundle/Info.plist")" = RawResources.bundle
for official_output in "$@"; do
  test -e "$official_output"
done
printf 'verified\n' > "$output"
""",
        inputs = [bundle] + official_files,
        outputs = [verified],
    )

    executable = ctx.actions.declare_file(
        "dual_aspect_resource_bundle_test.sh",
    )
    ctx.actions.write(
        executable,
        content = """\
#!/bin/bash
set -euo pipefail
readonly marker="$TEST_SRCDIR/$TEST_WORKSPACE/{marker}"
[[ "$(cat "$marker")" == verified ]]
""".format(marker = verified.short_path),
        is_executable = True,
    )

    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [verified]),
    )]

dual_aspect_resource_bundle_test = rule(
    implementation = _dual_aspect_resource_bundle_test_impl,
    attrs = {
        "target": attr.label(
            aspects = [apple_resource_aspect, _preview_aspect],
            mandatory = True,
        ),
    },
    test = True,
)

def _multiple_generators_resource_bundle_test_impl(ctx):
    bundles = [
        bundle.file
        for target in [ctx.attr.first_target, ctx.attr.second_target]
        for bundle in target[XcodeProjInfo].inputs._preview_resource_bundles.to_list()
        if bundle.name == "RawResources"
    ]
    if bundles[0].path == bundles[1].path:
        fail("Different Xcode project generators declared the same Preview bundle path: {}".format(
            bundles[0].path,
        ))

    verified = ctx.actions.declare_file("multiple_generators.verified")
    ctx.actions.run_shell(
        arguments = [verified.path] + [bundle.path for bundle in bundles],
        command = """\
set -euo pipefail
readonly output="$1"
shift
for bundle in "$@"; do
  test -f "$bundle/Info.plist"
  test -f "$bundle/Assets.car"
  test -f "$bundle/en.lproj/Localizable.strings"
  test "$(cat "$bundle/NestedResources.bundle/value.txt")" = nested-resource-value
done
diff -r "$1" "$2"
printf 'verified\\n' > "$output"
""",
        inputs = bundles,
        outputs = [verified],
    )
    executable = ctx.actions.declare_file("multiple_generators_test.sh")
    ctx.actions.write(
        executable,
        content = """\
#!/bin/bash
set -euo pipefail
readonly marker="$TEST_SRCDIR/$TEST_WORKSPACE/{marker}"
[[ "$(cat "$marker")" == verified ]]
""".format(marker = verified.short_path),
        is_executable = True,
    )
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [verified]),
    )]

multiple_generators_resource_bundle_test = rule(
    implementation = _multiple_generators_resource_bundle_test_impl,
    attrs = {
        "first_target": attr.label(
            aspects = [_preview_aspect],
            mandatory = True,
        ),
        "second_target": attr.label(
            aspects = [_second_preview_aspect],
            mandatory = True,
        ),
    },
    test = True,
)

_ResourceSelectionInfo = provider(fields = ["files"])

def _shared_resource_selection_impl(target, ctx):
    selected = input_files.preview_resource_bundle_files(target[XcodeProjInfo].inputs)
    for name in ["deps", "data"]:
        deps = getattr(ctx.rule.attr, name, [])
        if type(deps) == "dict":
            deps = [dep for values in deps.values() for dep in values]
        for dep in deps:
            if _ResourceSelectionInfo not in dep:
                continue
            for file in dep[_ResourceSelectionInfo].files:
                if file not in selected:
                    fail("{} did not reuse dependency {} resource producer {}".format(
                        target.label,
                        dep.label,
                        file.path,
                    ))
    return [_ResourceSelectionInfo(files = selected)]

_shared_resource_selection = aspect(
    implementation = _shared_resource_selection_impl,
    attr_aspects = ["deps", "data"],
    requires = [_preview_aspect],
)

def _shared_consumer_resource_bundle_test_impl(ctx):
    for consumer in [ctx.attr.app, ctx.attr.framework]:
        if not consumer[_ResourceSelectionInfo].files:
            fail("{} lost its resource bundle closure".format(consumer.label))
    executable = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(executable, "#!/bin/bash\nexit 0\n", is_executable = True)
    return [DefaultInfo(executable = executable)]

shared_consumer_resource_bundle_test = rule(
    implementation = _shared_consumer_resource_bundle_test_impl,
    attrs = {
        name: attr.label(aspects = [_shared_resource_selection], mandatory = True)
        for name in ["app", "framework"]
    },
    test = True,
)
