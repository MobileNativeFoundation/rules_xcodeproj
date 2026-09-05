#!/usr/bin/env python3
"""Builds a canonical build-proxy manifest from generator shard entries."""

import argparse
from pathlib import Path

from xcodeproj.internal import build_proxy_manifest_lib


def main(argv=None) -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("generator_label")
    parser.add_argument("bazel_path")
    parser.add_argument("project_container")
    parser.add_argument("--bazel-environment-key", action="append", default=[])
    parser.add_argument("fragments", nargs="*", type=Path)
    args = parser.parse_intermixed_args(argv)
    build_proxy_manifest_lib.write(
        args.output,
        args.fragments,
        bazel_path=args.bazel_path,
        bazel_environment_keys=args.bazel_environment_key,
        generator_label=args.generator_label,
        project_container=args.project_container,
    )


if __name__ == "__main__":
    main()
