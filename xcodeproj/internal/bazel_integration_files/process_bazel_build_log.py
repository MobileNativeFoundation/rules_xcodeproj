#!/usr/bin/python3

import os
import re
import subprocess
import sys
from typing import List


def _main(command: List[str]) -> None:
    srcroot = os.getenv("SRCROOT")
    if not srcroot:
        sys.exit("SRCROOT environment variable must be set")

    execution_root = os.getenv("PROJECT_DIR")
    if not execution_root:
        sys.exit("PROJECT_DIR environment variable must be set")

    bazel_out_directory = os.getenv("BAZEL_OUT")
    if not bazel_out_directory:
        sys.exit("BAZEL_OUT environment variable must be set")
    bazel_out_prefix = bazel_out_directory[:-(len("/bazel-out")+1)]
    if not bazel_out_prefix.startswith("/"):
        bazel_out_prefix = f"{srcroot}/{bazel_out_prefix}"

    external_directory = os.getenv("BAZEL_EXTERNAL")
    if not external_directory:
        sys.exit("BAZEL_EXTERNAL environment variable must be set")
    external_prefix = bazel_out_directory[:-(len("/external")+1)]
    if not external_prefix.startswith("/"):
        external_prefix = f"{srcroot}/{external_prefix}"

    should_strip_color = os.getenv("COLOR_DIAGNOSTICS", default="YES") != "YES"

    strip_color = re.compile(r"\x1b\[[0-9;]{1,}[A-Za-z]")
    relative_diagnostic = re.compile(
        r"^.+?:\d+(:\d+)?: (error|warning): ."
    )

    def _replacement(match: re.Match) -> str:
        message = match.group(0)

        # Uppercase the first letter of the (actual) message
        message = message[:-1] + message[-1].upper()

        if message.startswith(execution_root):
            # VFS overlays can make paths absolute, so make them relative again
            message = message[(len(execution_root) + 1):]

        if message.startswith("/"):
            # If still an absolute path, don't add a prefix
            return message

        if message.startswith("bazel-out/"):
            prefix = bazel_out_prefix
        elif message.startswith("external/"):
            prefix = external_prefix
        else:
            prefix = srcroot

        return f"{prefix}/{message}"

    process = subprocess.Popen(
        command, bufsize=1, stderr=subprocess.PIPE, universal_newlines=True
    )
    assert process.stderr

    while process.poll() is None:
        input_line = process.stderr.readline().rstrip()

        if should_strip_color:
            input_line = strip_color.sub("", input_line)

        if not input_line:
            continue

        output_line = relative_diagnostic.sub(_replacement, input_line)
        print(output_line, flush=True)

    sys.exit(process.returncode)


if __name__ == "__main__":
    _main(sys.argv[1:])
