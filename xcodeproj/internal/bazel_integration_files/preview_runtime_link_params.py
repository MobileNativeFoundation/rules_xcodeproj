#!/usr/bin/python3

"""Queries the selected Clang driver for a native static Preview's runtimes.

This emits only runtime response arguments. The caller owns the original link
inputs, native-static gating, explicit policy collection and atomic publication.
No compiler/linker job in the driver's -### plan is executed.
"""

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys


_DRIVER_POLICY = {
    "-fprofile-generate", "-fno-profile-generate",
    "-fprofile-instr-generate", "-fno-profile-instr-generate",
    "-nostdlib", "-nodefaultlibs", "-nostartfiles", "-nostdlib++",
    "-fobjc-link-runtime", "-fno-objc-link-runtime",
}
_VALUED_DRIVER_POLICY = (
    "-fprofile-generate=", "-fprofile-instr-generate=",
    "-rtlib=", "--rtlib=",
)


def _validate_policy(policy):
    if not isinstance(policy, (list, tuple)):
        raise ValueError("driver policy must be an ordered array of strings")
    for value in policy:
        if (not isinstance(value, str) or
            any(character in value for character in "\0\n\r") or
            not (value in _DRIVER_POLICY or any(
                value.startswith(prefix) and len(value) > len(prefix)
                for prefix in _VALUED_DRIVER_POLICY
            ))):
            raise ValueError(f"unsupported runtime driver-policy argument: {value!r}")


def _linker_job(plan):
    # Clang -### prints shell-quoted commands on stderr, alongside version and
    # diagnostic lines. Compilation planning may also print a cc1 job.
    jobs = []
    for line in plan.splitlines():
        if not line.lstrip().startswith('"'):
            continue
        command = shlex.split(line)
        if command and Path(command[0]).name in ("ld", "ld-classic"):
            jobs.append(command)
    if len(jobs) != 1:
        raise ValueError(f"expected one Darwin linker job, found {len(jobs)}")
    job = jobs[0]
    if (not Path(job[0]).is_absolute() or
        "-dylib" not in job or "-platform_version" not in job):
        raise ValueError("unsupported Darwin dynamic-link plan")
    platform_index = job.index("-platform_version") + 1
    platform = job[platform_index:platform_index + 3]
    if (job.count("-platform_version") != 1 or len(platform) != 3 or
        any(not value or value.startswith("-") for value in platform) or
        any(not re.fullmatch(r"[0-9]+(?:\.[0-9]+)*", value) for value in platform[1:])):
        raise ValueError("incomplete Darwin platform-version group")
    return job


def _option_value(job, option):
    if job.count(option) != 1:
        raise ValueError(f"expected one {option} in Darwin linker job")
    index = job.index(option) + 1
    if index == len(job) or job[index].startswith("-"):
        raise ValueError(f"missing {option} value in Darwin linker job")
    return job[index]


def _runtime_args(job):
    result = []
    index = 1
    while index < len(job):
        path = Path(job[index])
        if not (path.name.startswith("libclang_rt.") and path.suffix == ".a"):
            index += 1
            continue
        if (not path.is_absolute() or not path.is_file() or
            any(character in str(path) for character in "\0\n\r")):
            raise ValueError(f"compiler-runtime archive is not an absolute file: {path}")
        if job[index - 1] in ("-force_load", "-weak_library", "-reexport_library"):
            raise ValueError(f"unsupported bound compiler-runtime archive: {path}")
        result.append(str(path))
        index += 1
        # Preserve only complete defaults immediately associated with this
        # runtime. Never import general linker flags or a platform-name catalog.
        while index < len(job) and job[index] == "-sectalign":
            group = job[index:index + 4]
            if (len(group) != 4 or
                any(not value or value.startswith("-") for value in group[1:]) or
                not re.fullmatch(r"(?:0[xX])?[0-9a-fA-F]+", group[3])):
                raise ValueError("incomplete compiler-runtime -sectalign group")
            result.extend(group)
            index += 4
    return result


def runtime_link_args(driver, sdk, target, *, swift_profile=False, driver_policy=()):
    """Returns ordered lazy runtime inputs/defaults, not a complete link plan.

    Explicit driver policy follows the selected Swift IR-profile requirement.
    The driver decides suppression/order semantics. A valid plan can select no
    runtimes; no fixed archive count or guessed fallback is imposed.
    """
    driver, sdk = Path(driver), Path(sdk)
    if not driver.is_absolute() or not driver.is_file() or not os.access(driver, os.X_OK):
        raise ValueError(f"selected driver must be an absolute executable file: {driver}")
    if not sdk.is_absolute() or not sdk.is_dir():
        raise ValueError(f"selected SDK must be an absolute directory: {sdk}")
    if not re.fullmatch(r"[A-Za-z0-9_]+-apple-[A-Za-z0-9_.]+(?:-[A-Za-z0-9_]+)*", target):
        raise ValueError(f"expected one explicit Apple target triple: {target!r}")
    if not isinstance(swift_profile, bool):
        raise ValueError("Swift IR-profile requirement must be a boolean")
    _validate_policy(driver_policy)
    argv = [str(driver), "-###", "-dynamiclib", "-target", target, "-isysroot", str(sdk)]
    if swift_profile:
        argv.append("-fprofile-generate")
    argv.extend(driver_policy)
    argv.extend(["-x", "c", "/dev/null", "-o", "/dev/null"])
    context = f"driver={driver}, SDK={sdk}, target={target}"
    try:
        completed = subprocess.run(argv, capture_output=True, text=True, timeout=30)
        if completed.returncode:
            raise ValueError(f"driver planning exited {completed.returncode}: {completed.stderr.strip()}")
        job = _linker_job(completed.stderr)
        if _option_value(job, "-arch") != target.split("-", 1)[0]:
            raise ValueError("driver plan does not match the requested architecture")
        if Path(_option_value(job, "-syslibroot")).resolve() != sdk.resolve():
            raise ValueError("driver plan does not match the requested SDK")
        return _runtime_args(job)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        raise ValueError(f"Cannot plan Preview compiler runtimes ({context}): {error}") from error


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--driver", required=True)
    parser.add_argument("--sdk", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--swift-profile", choices=("YES", "NO"), required=True)
    parser.add_argument("--driver-policy-json", default="[]")
    arguments = parser.parse_args(argv)
    try:
        values = runtime_link_args(
            arguments.driver, arguments.sdk, arguments.target,
            swift_profile=arguments.swift_profile == "YES",
            driver_policy=json.loads(arguments.driver_policy_json),
        )
        # Clang/ld response quoting, not shell quoting. Compute everything before
        # writing stdout so a failed plan cannot append a partial runtime list.
        response = "".join('"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"\n' for value in values)
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    sys.stdout.write(response)
    return 0


if __name__ == "__main__":
    sys.exit(main())
