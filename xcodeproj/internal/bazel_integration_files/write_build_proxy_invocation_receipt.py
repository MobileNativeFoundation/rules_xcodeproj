#!/usr/bin/python3
"""Writes a redacted receipt for the exact generated Bazel invocation policy."""

import argparse
import json
import os
from pathlib import Path
import re
import tempfile


SENSITIVE_OPTION = re.compile(
    r"(?:^|--|[;, ])(?:remote_header|bes_header|remote_cache_header|"
    r"authorization|cookie|token|password)(?:=|:)|"
    r"(?:^|[=;, ])(?:[A-Za-z0-9_]*(?:TOKEN|PASSWORD|SECRET|CREDENTIAL|API_KEY)"
    r"[A-Za-z0-9_]*)=",
    re.IGNORECASE,
)


def _pairs(values, name):
    result = {}
    for value in values:
        key, separator, item = value.partition("=")
        if not separator or not key:
            raise ValueError(f"invalid {name} value: expected KEY=VALUE")
        if key in result:
            raise ValueError(f"duplicate {name} key: {key}")
        result[key] = item
    return result


def _validate_redaction(values):
    for value in values:
        if SENSITIVE_OPTION.search(value):
            raise ValueError("credential-bearing options are forbidden in receipts")


def _write_private_json(path, value):
    destination = path.expanduser().resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{destination.name}.",
        dir=destination.parent,
    )
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            json.dump(value, stream, indent=2, sort_keys=True)
            stream.write("\n")
        os.replace(temporary_name, destination)
    except BaseException:
        try:
            os.close(descriptor)
        except OSError:
            pass
        try:
            os.unlink(temporary_name)
        except OSError:
            pass
        raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--working-directory", required=True)
    parser.add_argument("--command", required=True)
    parser.add_argument("--startup-option", action="append", default=[])
    parser.add_argument("--bazelrc", action="append", default=[])
    parser.add_argument("--command-option", action="append", default=[])
    parser.add_argument("--target", action="append", default=[])
    parser.add_argument("--label", action="append", default=[])
    parser.add_argument("--output-group", action="append", default=[])
    parser.add_argument("--target-id", action="append", default=[])
    parser.add_argument("--environment-key", action="append", default=[])
    parser.add_argument("--mode", action="append", default=[])
    parser.add_argument("--materialization", action="append", default=[])
    parser.add_argument("--bep-path")
    args = parser.parse_args()

    _validate_redaction(
        args.startup_option + args.bazelrc + args.command_option + args.target
    )
    receipt = {
        "schemaVersion": 1,
        "workingDirectory": args.working_directory,
        "startupOptions": args.startup_option,
        "bazelrcs": args.bazelrc,
        "command": args.command,
        "commandOptions": args.command_option,
        "targets": sorted(set(args.target)),
        "labels": sorted(set(args.label)),
        "outputGroups": sorted(set(args.output_group)),
        "targetIDs": sorted(set(args.target_id)),
        "environmentKeys": sorted(set(args.environment_key)),
        "modes": _pairs(args.mode, "mode"),
        "materialization": _pairs(args.materialization, "materialization"),
        "provenance": {"bepPath": args.bep_path} if args.bep_path else {},
    }
    _write_private_json(args.output, receipt)


if __name__ == "__main__":
    main()
