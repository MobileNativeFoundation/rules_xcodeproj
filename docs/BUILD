load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@io_bazel_stardoc//stardoc:stardoc.bzl", "stardoc")

# Generating

_DOC_COMPONENTS = [
    "project_options",
    "providers",
    "top_level_target",
    "xcode_build_settings",
    "xcode_schemes",
    "xcodeproj",
    "xcschemes",
]

[
    stardoc(
        name = component,
        out = "{}.md".format(component),
        input = "//xcodeproj/internal/docs:{}.bzl".format(component),
        tags = [
            "manual",
            "no-sandbox",  # https://github.com/bazelbuild/stardoc/issues/112
        ],
        deps = ["//xcodeproj/internal"],
    )
    for component in _DOC_COMPONENTS
]

genrule(
    name = "bazel",
    srcs = [
        "//xcodeproj/internal/docs:bazel.header.md",
        ":xcodeproj",
        ":top_level_target",
        ":project_options",
        ":xcode_schemes",
        ":xcschemes",
        ":xcode_build_settings",
        ":providers",
    ],
    outs = ["bazel.generated.md"],
    cmd = """\
srcs=($(SRCS))

cat "$${srcs[0]}" > $@
for src in "$${srcs[@]:1}"; do
  sed '1,2d' "$$src" >> $@
done
""",
)

# Tests

diff_test(
    name = "diff_test",
    failure_message = "\nPlease update the docs by running\n    ./docs/update_docs.sh",
    file1 = "bazel.generated.md",
    file2 = "bazel.md",
    tags = ["manual"],
)

# Updating

_DOCS = [
    "bazel",
]

write_file(
    name = "gen_update",
    out = "update.sh",
    content = [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
    ] + [
        'cp -fv docs/{src}.generated.md "$BUILD_WORKSPACE_DIRECTORY/docs/{dst}.md"'.format(
            src = doc,
            dst = doc,
        )
        for doc in _DOCS
    ],
    tags = ["manual"],
)

sh_binary(
    name = "update",
    srcs = ["update.sh"],
    data = ["{}.generated.md".format(doc) for doc in _DOCS],
    tags = ["manual"],
)
