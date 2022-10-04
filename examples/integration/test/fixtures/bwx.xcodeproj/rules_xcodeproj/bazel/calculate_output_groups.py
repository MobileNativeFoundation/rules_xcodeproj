#!/usr/bin/python3

import datetime
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

def _calculate_label_and_target_ids(
        build_request_file,
        scheme_labels_and_target_ids,
        guid_labels,
        guid_target_ids):
    try:
        # The first time a certain buildRequest is used, the buildRequest.json
        # might not exist yet, so we for it to exist
        wait_counter = 0
        while not os.path.exists(build_request_file):
            if wait_counter == 0:
                now = datetime.datetime.now().strftime('%H:%M:%S')
                print(
                        f"""\
note: ({now}) "{build_request_file}" doesn't exist yet, waiting for it to be \
created...""",
                        file = sys.stderr,
                )
            if wait_counter == 10:
                now = datetime.datetime.now().strftime('%H:%M:%S')
                print(
                        f"""\
warning: ({now}) "{build_request_file}" still doesn't exist after 10 seconds. \
If happens frequently, or the cache is never created, please file a bug \
report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md""",
                        file = sys.stderr,
                )
            time.sleep(1)
            wait_counter += 1
        if wait_counter > 0:
            now = datetime.datetime.now().strftime('%H:%M:%S')
            print(
                    f"""\
note: ({now}) "{build_request_file}" created after {wait_counter} seconds.""",
                    file = sys.stderr,
            )

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

        labels_and_target_ids = []
        for target in build_request["configuredTargets"]:
            label = guid_labels.get(target["guid"])
            if not label:
                # `BazelDependency` and the like
                continue
            full_target_target_ids = guid_target_ids[target["guid"]]
            target_target_ids = (
                full_target_target_ids.get(command) or
                # Will only be `null` if `command == "buildFiles"` and there
                # isn't a different compile target id
                full_target_target_ids["build"]
            )
            target_id = _select_target_id(target_target_ids, platform)
            labels_and_target_ids.append((label, target_id))
    except Exception as error:
        print(
            f"""\
warning: Failed to parse '{build_request_file}':
{type(error).__name__}: {error}.

warning: Using scheme labels and target ids as a fallback. Please file a bug \
report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md""",
            file = sys.stderr,
        )
        return scheme_labels_and_target_ids

    if not labels_and_target_ids:
        print(
            f"""\
warning: Couldn't determine labels and target ids from PIFCache

warning: Using scheme labels and target ids as a fallback. Please file a bug \
report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md""",
            file = sys.stderr,
        )
        labels_and_target_ids = scheme_labels_and_target_ids

    return labels_and_target_ids

def _calculate_guid_labels_and_target_ids(base_objroot):
    pif_cache = f"{base_objroot}/XCBuildData/PIFCache"
    project_cache = f"{pif_cache}/project"
    target_cache = f"{pif_cache}/target"

    # The PIF cache will only be created before the `SetSessionUserInfo`
    # command, which normally happens when a project is opened. If Derived Data
    # is cleared  while the project is open
    if not (os.path.exists(project_cache) and os.path.exists(target_cache)):
        print(
            f"""\
error: PIFCache ({pif_cache}) doesn't exist. If you manually cleared Derived \
Data, you need to close and re-open the project for the PIFCache to be created \
again. Using the "Clean Build Folder" command instead (⇧ ⌘ K) won't trigger \
this error. If this error still happens after re-opening the project, please \
file a bug report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md""",
            file = sys.stderr,
        )
        sys.exit(1)

    project_pif = max(
        glob.iglob(f"{project_cache}/*"),
        key = os.path.getctime,
    )

    guid_payload_parent = f"{base_objroot}/guid_payload"
    guid_payload_path = f"""\
{guid_payload_parent}/{os.path.basename(project_pif)}.json"""

    if os.path.exists(guid_payload_path):
        with open(guid_payload_path, encoding = "utf-8") as f:
            payload = json.load(f)
            return payload["labels"], payload["targetIds"]

    with open(project_pif, encoding = "utf-8") as f:
        project_pif = json.load(f)

    targets = project_pif["targets"]

    guid_labels = {}
    guid_target_ids = {}
    for target_name in targets:
        target_file = f"{target_cache}/{target_name}-json"
        with open(target_file, encoding = "utf-8") as f:
            target_pif = json.load(f)

        label = None
        build_target_ids = {"key": "BAZEL_TARGET_ID"}
        compile_target_ids = {"key": "BAZEL_COMPILE_TARGET_ID"}
        for configuration in target_pif["buildConfigurations"]:
            for key, value in configuration["buildSettings"].items():
                if key.startswith("BAZEL_TARGET_ID"):
                    build_target_ids[_platform_from_build_key(key)] = value
                elif key.startswith("BAZEL_COMPILE_TARGET_ID"):
                    compile_target_ids[_platform_from_compile_key(key)] = value
                elif key == "BAZEL_LABEL":
                    label = value

        if not label:
            # `BazelDependency` and the like
            continue

        target_ids = {
            "build": build_target_ids,
        }
        if len(compile_target_ids) > 1:
            target_ids["buildFiles"] = compile_target_ids

        guid = target_pif["guid"]
        guid_labels[guid] = label
        guid_target_ids[guid] = target_ids

    os.makedirs(guid_payload_parent, exist_ok = True)
    with open(guid_payload_path, "w", encoding = "utf-8") as f:
        payload = {
            "labels": guid_labels,
            "targetIds": guid_target_ids,
        }
        json.dump(payload, f)

    return guid_labels, guid_target_ids

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
        scheme_label_and_target_ids = []
        for label_and_target_id in set(f.read().splitlines()):
            components = label_and_target_id.split(",")
            scheme_label_and_target_ids.append((components[0], components[1]))

    prefixes = prefixes_str.split(",")

    if action == "indexbuild":
        # buildRequest for Index Build includes all targets, so we have to
        # fall back to the scheme labels and target ids (which are actually set
        # by the "Copy Bazel Outputs" script)
        labels_and_target_ids = scheme_label_and_target_ids
    else:
        try:
            build_request_file = _calculate_build_request_file(objroot)
            guid_labels, guid_target_ids = (
                _calculate_guid_labels_and_target_ids(base_objroot)
            )
        except Exception:
            print(
                f"""\
warning: Failed to calculate labels and target ids from PIFCache:
{traceback.format_exc()}
warning: Using scheme labels and target ids as a fallback. Please file a bug \
report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md""",
                file = sys.stderr,
            )
            labels_and_target_ids = scheme_label_and_target_ids
        else:
            labels_and_target_ids = _calculate_label_and_target_ids(
                build_request_file,
                scheme_label_and_target_ids,
                guid_labels,
                guid_target_ids,
            )

    print("\n".join(
        [
            f"{label}\n{prefix} {id}"
            for label, id in labels_and_target_ids
            for prefix in prefixes
        ],
    ))


if __name__ == "__main__":
    _main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
