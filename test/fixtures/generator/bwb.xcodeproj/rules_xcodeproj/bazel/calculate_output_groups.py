#!/usr/bin/python3

import glob
import json
import os
import sys
import time
import traceback

# Ordered the same as we order platforms in the generated Xcode project, except
# macOS is last
_DEVICE_PLATFORMS = {
    "iphoneos": None,
    "appletvos": None,
    "watchos": None,
    "macosx": None,
}
_SIMULATOR_PLATFORMS = {
    "iphonesimulator": None,
    "appletvsimulator": None,
    "watchsimulator": None,
    "macosx": None,
}

def _calculate_build_request_file(objroot):
    build_description_cache = max(
        glob.iglob(f"{objroot}/XCBuildData/BuildDescriptionCacheIndex-*"),
        key = os.path.getctime,
    )
    with open(build_description_cache, 'rb') as f:
        f.seek(-32, os.SEEK_END)
        build_request_id = f.read().decode('ASCII')
    return f"{objroot}/XCBuildData/{build_request_id}-buildRequest.json"

def _calculate_output_group_target_ids(
        build_request_file,
        scheme_target_ids,
        guid_target_ids):
    try:
        # The first time a certain buildRequest is used, the buildRequest.json
        # might not exist yet, so we wait a bit for it to exist
        wait_counter = 0
        time_to_wait = 10
        while not os.path.exists(build_request_file):
            time.sleep(1)
            wait_counter += 1
            if wait_counter > time_to_wait:
                break

        with open(build_request_file, encoding = "utf-8") as f:
            # Parse the build-request.json file
            build_request = json.load(f)

        # Xcode gets "stuck" in the `buildFiles` or `build` command for
        # top-level targets, so we can't reliably change commands here. Leaving
        # the code in place in case this is fixed in the future, or we want to
        # do something similar in an XCBBuildService proxy.
        #
        # command = (
        #     build_request.get("_buildCommand2", {}).get("command", "build")
        # )
        command = "build"
        platform = (
            build_request["parameters"]["activeRunDestination"]["platform"]
        )

        target_ids = []
        for target in build_request["configuredTargets"]:
            full_target_target_ids = guid_target_ids[target["guid"]]
            target_target_ids = (
                full_target_target_ids.get(command) or
                # Will only be `null` if `command == "buildFiles"`` and there
                # isn't a different compile target id
                full_target_target_ids["build"]
            )
            target_ids.append(_select_target_id(
                target_target_ids,
                platform,
            ))
    except Exception as error:
        print(
            f"""\
warning: Failed to parse '{build_request_file}':
{type(error).__name__}: {error}.

warning: Using scheme target ids as a fallback. Please file a bug report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md.""",
            file = sys.stderr,
        )
        return scheme_target_ids

    if not target_ids:
        print(
            f"""\
warning: Couldn't deteremine target ids from PIFCache ({target_ids})

warning: Using scheme target ids as a fallback. Please file a bug report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md.""",
            file = sys.stderr,
        )
        target_ids = scheme_target_ids

    return target_ids

def _calculate_guid_target_ids(base_objroot):
    pif_cache = f"{base_objroot}/XCBuildData/PIFCache"

    project_pif = max(
        glob.iglob(f"{pif_cache}/project/*"),
        key = os.path.getctime,
    )

    guid_target_ids_parent = f"{base_objroot}/guid_target_ids"
    guid_target_ids_path = f"""\
{guid_target_ids_parent}/{os.path.basename(project_pif)}_v2.json"""

    if os.path.exists(guid_target_ids_path):
        with open(guid_target_ids_path, encoding = "utf-8") as f:
            return json.load(f)

    with open(project_pif, encoding = "utf-8") as f:
        project_pif = json.load(f)

    targets = project_pif["targets"]

    target_cache = f"{pif_cache}/target"

    guid_target_ids = {}
    for target_name in targets:
        target_file = f"{target_cache}/{target_name}-json"
        with open(target_file, encoding = "utf-8") as f:
            target_pif = json.load(f)

        build_target_ids = {"key": "BAZEL_TARGET_ID"}
        compile_target_ids = {"key": "BAZEL_COMPILE_TARGET_ID"}
        for configuration in target_pif["buildConfigurations"]:
            for key, value in configuration["buildSettings"].items():
                if key.startswith("BAZEL_TARGET_ID"):
                    build_target_ids[_platform_from_build_key(key)] = value
                elif key.startswith("BAZEL_COMPILE_TARGET_ID"):
                    compile_target_ids[_platform_from_compile_key(key)] = value

        target_ids = {
            "build": build_target_ids,
        }
        if len(compile_target_ids) > 1:
            target_ids["buildFiles"] = compile_target_ids

        guid_target_ids[target_pif["guid"]] = target_ids

    os.makedirs(guid_target_ids_parent, exist_ok = True)
    with open(guid_target_ids_path, "w", encoding = "utf-8") as f:
        json.dump(guid_target_ids, f)

    return guid_target_ids

def _platform_from_build_key(key):
    if key.startswith("BAZEL_TARGET_ID[sdk="):
        return key[20:-2]
    return ""

def _platform_from_compile_key(key):
    if key.startswith("BAZEL_COMPILE_TARGET_ID[sdk="):
        return key[28:-2]
    return ""

def _select_target_id(target_ids, platform):
    key = target_ids["key"]

    platforms = {platform: None}

    # We need to try other similar platforms (i.e. other simulator platforms if
    # `platform`` is for a simulator). This is to support schemes with targets
    # of multiple platforms in them. Because `dict` is insertion ordered,
    # `platform` will be checked first.
    platforms.update(_similar_platforms(platform))

    for platform in platforms:
        target_id = target_ids.get(platform)
        if target_id:
            if target_id == f"$({key})":
                return target_ids[""]
            return target_id
    return target_ids[""]

def _similar_platforms(platform):
    if platform == "macosx" or "simulator" in platform:
        return _SIMULATOR_PLATFORMS
    return _DEVICE_PLATFORMS

def _main(action, objroot, base_objroot, scheme_target_id_file, prefixes_str):
    if not os.path.exists(scheme_target_id_file):
        return

    with open(scheme_target_id_file, encoding = "utf-8") as f:
        scheme_target_ids = set(f.read().splitlines())

    prefixes = prefixes_str.split(",")

    if action == "indexbuild":
        # buildRequest for Index Build includes all targets, so we have to
        # fall back to the scheme target ids (which are actually set by the
        # "Copy Bazel Outputs" script)
        target_ids = scheme_target_ids
    else:
        try:
            build_request_file = _calculate_build_request_file(objroot)
            guid_target_ids = _calculate_guid_target_ids(base_objroot)
        except Exception:
            print(
                f"""\
warning: Failed to calculate target ids from PIFCache:
{traceback.format_exc()}
warning: Using scheme target ids as a fallback. Please file a bug report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md.""",
                file = sys.stderr,
            )
            target_ids = scheme_target_ids
        else:
            target_ids = _calculate_output_group_target_ids(
                build_request_file,
                scheme_target_ids,
                guid_target_ids,
            )

    print("\n".join(
        [f"{prefix} {id}" for id in target_ids for prefix in prefixes],
    ))


if __name__ == "__main__":
    _main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
