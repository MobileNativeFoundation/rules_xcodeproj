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

info_plists = struct(
    get_file = _get_file,
    get_file_from_objc_provider = _get_file_from_objc_provider,
)
