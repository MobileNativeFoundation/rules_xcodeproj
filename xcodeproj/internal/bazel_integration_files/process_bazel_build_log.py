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
    has_relative_diagnostic = False

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

    def _process_log_line(line: str):
        input_line = line.rstrip()

        if should_strip_color:
            input_line = strip_color.sub("", input_line)

        if not input_line:
            return

        output_line = relative_diagnostic.sub(_replacement, input_line)
        # Record if we have performed a relative diagnostic substitution.
        if output_line != input_line:
            nonlocal has_relative_diagnostic
            has_relative_diagnostic = True

        print(output_line, flush=True)

    while process.poll() is None:
        _process_log_line(process.stderr.readline())

    for line in process.stderr:
        _process_log_line(line)

    # If the Bazel invocation failed and there was no formatted error found, 
    # print a nicer error message instead of a cryptic in Xcode:
    # 'Command PhaseScriptExecution failed with a nonzero exit code'
    if process.returncode != 0 and not has_relative_diagnostic:
        print("error: The bazel build failed, please check the report navigator, "
            "which may have more context about the failure.")

    sys.exit(process.returncode)


if __name__ == "__main__":
    _main(sys.argv[1:])
