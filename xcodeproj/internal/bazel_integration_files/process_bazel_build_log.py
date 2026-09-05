#!/usr/bin/python3

import os
import re
import signal
import subprocess
import sys
import threading
from typing import List, Optional


STRIP_COLOR_RE = re.compile(r"\x1b\[[0-9;]{1,}[A-Za-z]")
RELATIVE_DIAGNOSTICS_RE = re.compile(
    r"""
    ^
    (?P<loc>.+?:\d+(?::\d+)?:\s)  # Capture location (e.g. "foo/bar:12:3: ")
    (?:fatal\s)?                  # Dropping "fatal "
    (?P<sev>(?:error|warning):\s) # Capture severity
    (?P<msg>.*)                   # Capture the rest of the message
    """,
    re.VERBOSE,
)


def _uppercase_first_letter(s: str) -> str:
    return s[:1].upper() + s[1:]


def _main(command: List[str]) -> None:

    proxy_mode = bool(os.getenv("SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR"))
    cancel_grace_seconds = float(
        os.getenv("SWIFTBUILD_BAZEL_PROXY_CANCEL_GRACE_SECONDS", "5.0")
    )
    cancel_grace_seconds = min(max(cancel_grace_seconds, 0.1), 5.0)
    process: Optional[subprocess.Popen[str]] = None
    kill_timer: Optional[threading.Timer] = None

    def _signal_process_group(sig: signal.Signals) -> None:
        if not process:
            return
        try:
            if proxy_mode:
                # The group can outlive its leader when a nested tool ignores
                # SIGTERM, so escalation must still address the original PGID
                # after the wrapper process has exited.
                os.killpg(process.pid, sig)
            elif process.poll() is None:
                process.send_signal(sig)
        except ProcessLookupError:
            return

    def _force_kill() -> None:
        _signal_process_group(signal.SIGKILL)

    def _signal_handler(signum, frame):
        """Forward cancellation to Bazel and bound the shutdown grace period."""
        nonlocal kill_timer
        signal_name = signal.Signals(signum).name
        print(f"\nReceived signal {signal_name} ({signum})\n", file=sys.stderr)
        if not proxy_mode:
            return
        _signal_process_group(signal.SIGTERM)
        if kill_timer is None:
            kill_timer = threading.Timer(cancel_grace_seconds, _force_kill)
            kill_timer.daemon = True
            kill_timer.start()

    # Preserve native integration behavior outside proxy mode. Proxy mode also
    # owns SIGTERM so cancelling the Swift Build operation reaches Bazel.
    signal.signal(signal.SIGINT, _signal_handler)
    if proxy_mode:
        signal.signal(signal.SIGTERM, _signal_handler)

    srcroot = os.getenv("SRCROOT")
    if not srcroot:
        sys.exit("SRCROOT environment variable must be set")

    execution_root = os.getenv("PROJECT_DIR")
    if not execution_root:
        sys.exit("PROJECT_DIR environment variable must be set")

    bazel_out_directory = os.getenv("BAZEL_OUT")
    if not bazel_out_directory:
        sys.exit("BAZEL_OUT environment variable must be set")
    bazel_out_prefix = bazel_out_directory[:-len("/bazel-out")]
    if not bazel_out_prefix.startswith("/"):
        bazel_out_prefix = f"{srcroot}/{bazel_out_prefix}"

    external_directory = os.getenv("BAZEL_EXTERNAL")
    if not external_directory:
        sys.exit("BAZEL_EXTERNAL environment variable must be set")
    external_prefix = bazel_out_directory[:-len("/external")]
    if not external_prefix.startswith("/"):
        external_prefix = f"{srcroot}/{external_prefix}"

    should_strip_color = os.getenv("COLOR_DIAGNOSTICS", default="YES") != "YES"

    has_relative_diagnostic = False

    def _replacement(match: re.Match) -> str:
        message = f"""\
{match.group("loc")}{match.group("sev")}{_uppercase_first_letter(match.group("msg"))}\
"""

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
        command,
        bufsize=1,
        stderr=subprocess.PIPE,
        start_new_session=proxy_mode,
        universal_newlines=True,
    )
    assert process.stderr

    def _process_log_line(line: str):
        input_line = line.rstrip()

        if should_strip_color:
            input_line = STRIP_COLOR_RE.sub("", input_line)

        if not input_line:
            return

        output_line = RELATIVE_DIAGNOSTICS_RE.sub(_replacement, input_line)
        # Record if we have performed a relative diagnostic substitution.
        if output_line != input_line:
            nonlocal has_relative_diagnostic
            has_relative_diagnostic = True

        print(output_line, flush=True)

    while process.poll() is None:
        _process_log_line(process.stderr.readline())

    for line in process.stderr:
        _process_log_line(line)

    if kill_timer is not None:
        kill_timer.cancel()

    # If the Bazel invocation failed and there was no formatted error found,
    # print a nicer error message instead of a cryptic in Xcode:
    # 'Command PhaseScriptExecution failed with a nonzero exit code'
    if process.returncode != 0 and not has_relative_diagnostic:
        print("error: The bazel build failed, please check the report navigator, "
            "which may have more context about the failure.")

    sys.exit(process.returncode)


if __name__ == "__main__":
    _main(sys.argv[1:])
