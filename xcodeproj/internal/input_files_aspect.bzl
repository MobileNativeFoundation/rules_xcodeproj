"""Implementation of the `input_files_aspect` aspect."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@build_bazel_rules_apple//apple:providers.bzl", "AppleBundleInfo")
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:providers.bzl",
    "InputFileAttributesInfo",
)
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj/internal:logging.bzl",
    "warn",
)

InputFilesInfo = provider(
    "Provides information about input files of a target.",
    fields = {
        "generated": """\
A `list` of generated `File`s that are inputs to this target. These files are
also included in the other catagories (e.g. `srcs` or `other`). They are
included in their own field for ease of access.
""",
        "hdrs": """\
A `list` of `File`s that are inputs to this target's `hdrs`-like attributes.
""",
        "non_arc_srcs": """\
A `list` of `File`s that are inputs to this target's `non_arc_srcs`-like
attributes.
""",
        "non_generated": """\
A list of non-generated `File`s that are inputs to this target.
""",
        "other": """\
A `list` of `File`s that are inputs to this target that didn't fall into one of
the more specific (e.g. `srcs`) catagories.
""",
        "srcs": """\
A `list` of `File`s that are inputs to this target's `srcs`-like attributes.
""",
        "transitive_non_generated": """\
A list of `depset`s of non-generated `File`s that are inputs to this target's
transitive dependencies.
""",
    },
)

# Utility

# Extensions that represent built targets. If these are seen in
# `InputFilesInfo.generated`, then it means an attr wasn't properly excluded.
_SUSPECT_GENERATED_EXTENSIONS = (
    ".a",
    ".app",
    ".appex",
    ".bundle",
    ".dylib",
    ".framework",
    ".kext",
    ".mdimporter",
    ".prefPane",
    ".qlgenerator",
    ".swiftdoc",
    ".swiftinterface",
    ".swiftmodule",
    ".xcframework",
    ".xctest",
    ".xpc",
)

def _should_ignore_attr(attr, *, excluded_attrs):
    return (
        attr in excluded_attrs or
        # We don't want to include implicit dependencies
        attr.startswith("_") or
        # These are actually Starklark methods, so ignore them
        attr in ("to_json", "to_proto")
    )

def _is_test_target(target):
    """Returns whether the given target is for test purposes or not."""
    if AppleBundleInfo not in target:
        return False
    return target[AppleBundleInfo].product_type in (
        "com.apple.product-type.bundle.ui-testing",
        "com.apple.product-type.bundle.unit-test",
    )

# Aspects

def _default_input_file_attributes_aspect_impl(target, ctx):
    if InputFileAttributesInfo in target:
        return []

    srcs = ("srcs")
    non_arc_srcs = ()
    hdrs = ()
    if ctx.rule.kind == "cc_library":
        excluded = ("deps", "interface_deps", "win_def_file")
        hdrs = ("hdrs", "textual_hdrs")
    elif ctx.rule.kind == "objc_library":
        excluded = ("deps", "runtime_deps")
        non_arc_srcs = ("non_arc_srcs")
        hdrs = ("hdrs", "textual_hdrs")
    elif ctx.rule.kind == "swift_library":
        excluded = ("deps", "private_deps")
    else:
        excluded = ["deps"]
        if _is_test_target(target):
            excluded.append("test_host")

    return [
        InputFileAttributesInfo(
            excluded = excluded,
            non_arc_srcs = non_arc_srcs,
            srcs = srcs,
            hdrs = hdrs,
        ),
    ]

_default_input_file_attributes_aspect = aspect(
    implementation = _default_input_file_attributes_aspect_impl,
    attr_aspects = ["*"],
)

def _input_files_aspect_impl(target, ctx):
    attrs_info = target[InputFileAttributesInfo]

    generated = []
    non_generated = []
    transitive_non_generated = []
    srcs = []
    non_arc_srcs = []
    hdrs = []
    other = []

    # buildifier: disable=uninitialized
    def _handle_file(file, *, attr):
        if file:
            if file.is_source:
                non_generated.append(file)
            else:
                generated.append(file)

            if attr in attrs_info.srcs:
                srcs.append(file)
            elif attr in attrs_info.non_arc_srcs:
                non_arc_srcs.append(file)
            elif attr in attrs_info.hdrs:
                hdrs.append(file)
            else:
                other.append(file)

    # buildifier: disable=uninitialized
    def _handle_dep(dep):
        if dep and InputFilesInfo in dep:
            info = dep[InputFilesInfo]
            transitive_non_generated.append(
                depset(
                    info.non_generated,
                    transitive = info.transitive_non_generated,
                ),
            )

    excluded_attrs = attrs_info.excluded

    for attr in dir(ctx.rule.files):
        if _should_ignore_attr(attr, excluded_attrs = excluded_attrs):
            continue
        dep = getattr(ctx.rule.attr, attr)
        if type(dep) == "list":
            for dep in dep:
                _handle_dep(dep)
        else:
            _handle_dep(dep)
        for file in getattr(ctx.rule.files, attr):
            _handle_file(file, attr = attr)

    for attr in dir(ctx.rule.file):
        if _should_ignore_attr(attr, excluded_attrs = excluded_attrs):
            continue
        _handle_dep(getattr(ctx.rule.attr, attr))
        _handle_file(getattr(ctx.rule.file, attr), attr = attr)

    # Sanity check to insure that we are excluding files correctly
    suspect_files = [
        file
        for file in generated
        if paths.split_extension(file.path)[1] in _SUSPECT_GENERATED_EXTENSIONS
    ]
    if suspect_files:
        warn("""\
Collected generated files for {target} that probably shouldn't have been \
collected:
{files}

If you are providing a custom `InputFileAttributesInfo`, ensure that the \
`excluded_attrs` attribute excludes the correct attributes.
If you think this is a bug, please file a bug report at \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md
""".format(target = target.label, files = suspect_files))

    return [
        InputFilesInfo(
            generated = generated,
            non_generated = non_generated,
            transitive_non_generated = transitive_non_generated,
            srcs = srcs,
            non_arc_srcs = non_arc_srcs,
            hdrs = hdrs,
            other = other,
        ),
    ]

input_files_aspect = aspect(
    implementation = _input_files_aspect_impl,
    attr_aspects = ["*"],
    requires = [_default_input_file_attributes_aspect],
)
