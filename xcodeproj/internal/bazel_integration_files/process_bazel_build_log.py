#!/usr/bin/python3

import json
import os
import re
import signal
import stat
import subprocess
import sys
import threading
import time
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
SUBCOMMAND_HEADER_RE = re.compile(
    r"^SUBCOMMAND: # .* target (?P<label>\S+) "
    r"\[action '(?P<description>.*)', configuration: (?P<configuration>[^,\]]+), "
    r"execution platform: (?P<execution_platform>[^,\]]+), "
    r"mnemonic: (?P<mnemonic>[^\]]+)\]$"
)
ACTION_START_STREAM_LEAF = "action-starts.jsonl"
MAXIMUM_ACTION_START_FIELD_BYTES = 16 * 1024
MAXIMUM_SUBCOMMAND_BLOCK_BYTES = 16 * 1024 * 1024


class _ActionStartStream:
    def __init__(self, path: str):
        if not os.path.isabs(path) or os.path.basename(path) != ACTION_START_STREAM_LEAF:
            raise ValueError("action-start stream path is unsafe")
        parent = os.path.dirname(path)
        parent_fd = os.open(parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            descriptor = os.open(
                ACTION_START_STREAM_LEAF,
                os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_CLOEXEC | os.O_NOFOLLOW,
                0o600,
                dir_fd=parent_fd,
            )
        finally:
            os.close(parent_fd)
        file_status = os.fstat(descriptor)
        if not stat.S_ISREG(file_status.st_mode) or file_status.st_nlink != 1:
            os.close(descriptor)
            raise ValueError("action-start stream is not a private regular file")
        os.fchmod(descriptor, 0o600)
        self._file = os.fdopen(descriptor, "w", encoding="utf-8", buffering=1)
        self._sequence = 0
        self._inside_subcommand = False
        self._subcommand_bytes = 0
        self.failed = False

    def close(self) -> None:
        self._file.close()

    def finish(self) -> None:
        if self._inside_subcommand:
            self.failed = True

    def consume(self, line: str) -> bool:
        """Returns True when a private subcommand line must not reach Xcode."""
        line_bytes = len(line.encode("utf-8", errors="replace"))
        if self._inside_subcommand:
            self._subcommand_bytes += line_bytes
            if self._subcommand_bytes > MAXIMUM_SUBCOMMAND_BLOCK_BYTES:
                self.failed = True
            if line.startswith("SUBCOMMAND:"):
                # A new header before Bazel's runner trailer means the previous block was not
                # framed as expected. Keep suppressing bytes and recover only to observe starts.
                self.failed = True
                self._begin(line)
            elif line.startswith("# Runner: "):
                self._inside_subcommand = False
                self._subcommand_bytes = 0
            return True

        if line.startswith("SUBCOMMAND:"):
            self._begin(line)
            return True
        return False

    def _begin(self, line: str) -> None:
        self._inside_subcommand = True
        self._subcommand_bytes = len(line.encode("utf-8", errors="replace"))
        match = SUBCOMMAND_HEADER_RE.fullmatch(line)
        if not match:
            self.failed = True
            return
        fields = {name: match.group(name).strip() for name in match.groupdict()}
        if any(not self._is_safe_field(value) for value in fields.values()):
            self.failed = True
            return
        self._sequence += 1
        record = {
            "configuration": fields["configuration"],
            "description": fields["description"],
            "executionPlatform": fields["execution_platform"],
            "label": fields["label"],
            "mnemonic": fields["mnemonic"],
            "observedTimeUnixMicroseconds": time.time_ns() // 1_000,
            "schemaVersion": 1,
            "sequence": self._sequence,
        }
        json.dump(record, self._file, ensure_ascii=False, separators=(",", ":"))
        self._file.write("\n")
        self._file.flush()

    @staticmethod
    def _is_safe_field(value: str) -> bool:
        return (
            bool(value)
            and len(value.encode("utf-8")) <= MAXIMUM_ACTION_START_FIELD_BYTES
            and all(ord(character) >= 0x20 and ord(character) != 0x7F for character in value)
        )


def _uppercase_first_letter(s: str) -> str:
    return s[:1].upper() + s[1:]


def _main(command: List[str]) -> None:

    proxy_mode = bool(os.getenv("SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR"))
    action_start_stream: Optional[_ActionStartStream] = None
    action_start_stream_path = os.getenv("SWIFTBUILD_BAZEL_PROXY_ACTION_STARTS_PATH")
    if action_start_stream_path:
        try:
            action_start_stream = _ActionStartStream(action_start_stream_path)
        except (OSError, ValueError):
            sys.exit("Bazel action-start stream could not be created safely")
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

        if action_start_stream and action_start_stream.consume(
            STRIP_COLOR_RE.sub("", input_line)
        ):
            return

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

    if action_start_stream:
        action_start_stream.finish()
        action_start_stream.close()

    # If the Bazel invocation failed and there was no formatted error found,
    # print a nicer error message instead of a cryptic in Xcode:
    # 'Command PhaseScriptExecution failed with a nonzero exit code'
    if process.returncode != 0 and not has_relative_diagnostic:
        print("error: The bazel build failed, please check the report navigator, "
            "which may have more context about the failure.")

    if action_start_stream and action_start_stream.failed:
        print("error: Bazel action-start metadata was malformed; private command details "
            "were suppressed.")

    sys.exit(process.returncode or (1 if action_start_stream and action_start_stream.failed else 0))


if __name__ == "__main__":
    _main(sys.argv[1:])
