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
        return getattr(target[AppleBinaryInfo], "infoplist", None)
    return None

def _adjust_for_xcode(file, default_app_icon_path, *, ctx):
    if file == None:
        return None

    output = ctx.actions.declare_file(
        "rules_xcodeproj/{}/Info.plist".format(ctx.rule.attr.name),
    )
    command = """\
cp "{input}" "{output}"
chmod u+w "{output}"
plutil -remove UIDeviceFamily \"{output}\" > /dev/null 2>&1 || true
""".format(input = file.path, output = output.path)

    if default_app_icon_path:
        command += """
plutil -insert CFBundleIconFile -string \"{app_icon_path}\" \"{output}\" > /dev/null 2>&1 || true
""".format(app_icon_path = default_app_icon_path, output = output.path)

    ctx.actions.run_shell(
        inputs = [file],
        outputs = [output],
        command = command,
    )

    return output

info_plists = struct(
    adjust_for_xcode = _adjust_for_xcode,
    get_file = _get_file,
)
