"""API to retrieve a launchd plist file from a `Target`."""

load(":link_opts.bzl", "link_opts")

def _get_file_from_objc_provider(objc_provider):
    """
    Retrieves the launchd plist from the TEXT section provided by the ObjcProvider.
    """

    launchd_plist_section = link_opts.get_section(
        objc_provider.linkopt.to_list(),
        "__TEXT",
        "__launchd_plist",
    )

    if launchd_plist_section == None:
        return None

    # Retrieve the launchd plist file from the link inputs
    for file in objc_provider.link_inputs.to_list():
        if file.path == launchd_plist_section.file:
            return file
    return None

def _get_file(target):
    if apple_common.AppleExecutableBinary in target:
        return _get_file_from_objc_provider(target[apple_common.AppleExecutableBinary].objc)
    return None

launchd_plists = struct(
    get_file = _get_file,
    get_file_from_objc_provider = _get_file_from_objc_provider,
)
