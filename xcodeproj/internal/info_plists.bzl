"""API to retrieve an `Info.plist` from a `Target`."""

load(
    "@build_bazel_rules_apple//apple:providers.bzl",
    "AppleBinaryInfo",
    "AppleBundleInfo",
)

def _get_file(target):
    if AppleBundleInfo in target:
        return target[AppleBundleInfo].infoplist
    elif AppleBinaryInfo in target:
        return target[AppleBinaryInfo].infoplist
    return None

def _adjust_for_xcode(file, *, ctx):
    if file == None:
        return None

    output = ctx.actions.declare_file(
        "rules_xcodeproj/{}/Info.plist".format(ctx.rule.attr.name),
    )

    ctx.actions.run_shell(
        inputs = [file],
        outputs = [output],
        command = """\
cp "{input}" "{output}"
chmod u+w "{output}"
plutil -remove UIDeviceFamily \"{output}\" > /dev/null 2>&1 || true
""".format(input = file.path, output = output.path),
    )

    return output

info_plists = struct(
    adjust_for_xcode = _adjust_for_xcode,
    get_file = _get_file,
)
