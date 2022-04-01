load("@build_bazel_rules_apple//apple:providers.bzl", "AppleBundleInfo")
load(":link_opts.bzl", "link_opts")

# def _get_path_from_linkopts_value(value):
#     # Example
#     # -Wl,-sectcreate,__TEXT,__info_plist,bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-fastbuild-ST-72fe7e1ef217/bin/examples/command_line/tool/tool.merged_infoplist-intermediates/Info.plist

#     # This simple split is probably sufficient. However, it will fail if there
#     # are quoted commas.
#     parts = value.split(",")
#     parts_len = len(parts)
#     for idx in range(parts_len):
#         part = parts[idx]
#         if part == "__info_plist":
#             path_idx = idx + 1
#             if path_idx >= parts_len:
#                 fail("Found __info_plist but there is no path.")
#             return parts[path_idx]

# def _get_path_from_linkopts(link_opts):
#     for value in link_opts.to_list():
#         path = _get_path_from_linkopts_value(value)
#         if path:
#             return path
#     return None

def _get_file_from_objc(objcProvider):
    # info_plist_path = _get_path_from_linkopts(objcProvider.linkopts)
    # info_plist_path = link_opts.get_value_after(objcProvider.linkopts, "__info_plist")
    info_plist_section = link_opts.get_section(
        objcProvider.linkopts,
        "__TEXT",
        "__info_plist",
    )
    if info_plist_section == None:
        return None
    return info_plist_section.file

    # TODO(chuck): FIX ME!

def _get_file(target):
    if AppleBundleInfo in target:
        return target[AppleBundleInfo].infoplist
    elif apple_common.Objc in target:
        return _get_file_from_objc(target[apple_common.Objc])
    return None

info_plists = struct(
    get_file = _get_file,
)
