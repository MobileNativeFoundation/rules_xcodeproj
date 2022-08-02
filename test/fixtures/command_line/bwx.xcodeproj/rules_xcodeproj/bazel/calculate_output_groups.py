#!/usr/bin/python3

import glob
import json
import os
import sys
import time
import traceback

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

        buildable_target_ids = []
        for target in build_request["configuredTargets"]:
            buildable_target_ids.extend(guid_target_ids[target["guid"]])
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

    target_ids = set(buildable_target_ids).intersection(scheme_target_ids)

    if not target_ids:
        print(
            f"""\
warning: Target ids from PIFCache ({buildable_target_ids}) \
didn't match any scheme target ids ({scheme_target_ids}).

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
{guid_target_ids_parent}/{os.path.basename(project_pif)}.json"""

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

        guid = target_pif["guid"]
        guid_target_ids[guid] = [
            value
            for configuration in target_pif["buildConfigurations"]
            for key, value in configuration["buildSettings"].items()
            if key.startswith("BAZEL_TARGET_ID")
        ]

    os.makedirs(guid_target_ids_parent, exist_ok = True)
    with open(guid_target_ids_path, "w", encoding = "utf-8") as f:
        json.dump(guid_target_ids, f)

    return guid_target_ids

def _main(objroot, base_objroot, scheme_target_id_file, prefix):
    if not os.path.exists(scheme_target_id_file):
        return

    with open(scheme_target_id_file, encoding = "utf-8") as f:
        scheme_target_ids = set(f.read().splitlines())

    if not scheme_target_ids:
        return

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

    print("\n".join([f"{prefix} {id}" for id in target_ids]))


if __name__ == "__main__":
    _main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
