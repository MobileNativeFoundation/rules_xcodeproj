"""API to retrieve an `Info.plist` from a `Target`."""

load("@build_bazel_rules_apple//apple:providers.bzl", "AppleBundleInfo")
load(":link_opts.bzl", "link_opts")

def _get_file_from_objc_provider(objc_provider):
    info_plist_section = link_opts.get_section(
        objc_provider.linkopt.to_list(),
        "__TEXT",
        "__info_plist",
    )
    if info_plist_section == None:
        return None

    # Retrieve the info plist file from the link inputs
    for file in objc_provider.link_inputs.to_list():
        if file.path == info_plist_section.file:
            return file
    return None

def _get_file(target):
    if AppleBundleInfo in target:
        return target[AppleBundleInfo].infoplist
    elif apple_common.Objc in target:
        return _get_file_from_objc_provider(target[apple_common.Objc])
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
    get_file_from_objc_provider = _get_file_from_objc_provider,
)
