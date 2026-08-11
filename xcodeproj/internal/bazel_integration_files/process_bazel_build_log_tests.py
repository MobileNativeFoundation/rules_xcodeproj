import json
import os
from pathlib import Path
import signal
import stat
import subprocess
import sys
import tempfile
import time
import unittest


class ProcessBazelBuildLogTests(unittest.TestCase):
    def test_proxy_publishes_action_start_and_suppresses_private_command_block(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            action_starts = root / "action-starts.jsonl"
            private_value = "private-action-value-must-not-reach-xcode"
            helper = "\n".join(
                [
                    "import sys",
                    "print('ordinary output before action', file=sys.stderr, flush=True)",
                    "print(\"SUBCOMMAND: # swift_library rule target //app:App "
                    "[action 'Compiling Swift module App', configuration: abc123, "
                    "execution platform: @@platforms//host:host, mnemonic: SwiftCompile]\", "
                    "file=sys.stderr, flush=True)",
                    f"print('(exec env TOKEN={private_value})', file=sys.stderr, flush=True)",
                    "print('# Configuration: abc123', file=sys.stderr, flush=True)",
                    "print('# Execution platform: @@platforms//host:host', "
                    "file=sys.stderr, flush=True)",
                    "print('# Runner: darwin-sandbox', file=sys.stderr, flush=True)",
                    "print('Sources/App.swift:12:3: warning: useful diagnostic', "
                    "file=sys.stderr, flush=True)",
                ]
            )
            result = self._run_wrapper(
                root,
                [sys.executable, "-c", helper],
                action_starts=action_starts,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("ordinary output before action", result.stdout)
            self.assertIn("warning: Useful diagnostic", result.stdout)
            self.assertNotIn("SUBCOMMAND", result.stdout)
            self.assertNotIn(private_value, result.stdout)
            self.assertNotIn("# Runner:", result.stdout)
            records = [json.loads(line) for line in action_starts.read_text().splitlines()]
            self.assertEqual(len(records), 1)
            self.assertEqual(records[0]["schemaVersion"], 1)
            self.assertEqual(records[0]["sequence"], 1)
            self.assertEqual(records[0]["label"], "//app:App")
            self.assertEqual(records[0]["configuration"], "abc123")
            self.assertEqual(records[0]["mnemonic"], "SwiftCompile")
            self.assertEqual(records[0]["description"], "Compiling Swift module App")
            self.assertGreater(records[0]["observedTimeUnixMicroseconds"], 0)
            self.assertEqual(stat.S_IMODE(action_starts.stat().st_mode), 0o600)

    def test_proxy_fails_closed_for_malformed_subcommand_header(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            action_starts = root / "action-starts.jsonl"
            private_value = "malformed-private-action-value"
            helper = "\n".join(
                [
                    "import sys",
                    "print('SUBCOMMAND: malformed', file=sys.stderr, flush=True)",
                    f"print('{private_value}', file=sys.stderr, flush=True)",
                    "print('# Runner: local', file=sys.stderr, flush=True)",
                ]
            )
            result = self._run_wrapper(
                root,
                [sys.executable, "-c", helper],
                action_starts=action_starts,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn(private_value, result.stdout)
            self.assertIn("private command details were suppressed", result.stdout)
            self.assertEqual(action_starts.read_text(), "")

    def test_proxy_rejects_preexisting_action_start_path(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            action_starts = root / "action-starts.jsonl"
            action_starts.write_text("foreign")
            result = self._run_wrapper(
                root,
                [sys.executable, "-c", "pass"],
                action_starts=action_starts,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("could not be created safely", result.stderr)
            self.assertEqual(action_starts.read_text(), "foreign")

    def test_proxy_cancellation_terminates_the_bazel_process_group(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            child_pid_path = root / "child.pid"
            helper = (
                "import os,signal,time;"
                f"open({str(child_pid_path)!r},'w').write(str(os.getpid()));"
                "signal.signal(signal.SIGTERM,signal.SIG_IGN);"
                "time.sleep(60)"
            )
            environment = os.environ.copy()
            environment.update(
                {
                    "BAZEL_EXTERNAL": str(root / "external"),
                    "BAZEL_OUT": str(root / "bazel-out"),
                    "PROJECT_DIR": str(root),
                    "SRCROOT": str(root),
                    "SWIFTBUILD_BAZEL_PROXY_CANCEL_GRACE_SECONDS": "0.1",
                    "SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR": str(root / "request"),
                }
            )
            wrapper = Path(__file__).with_name("process_bazel_build_log.py")
            process = subprocess.Popen(
                [sys.executable, str(wrapper), sys.executable, "-c", helper],
                env=environment,
                stderr=subprocess.PIPE,
                stdout=subprocess.PIPE,
                text=True,
            )
            deadline = time.monotonic() + 5
            while not child_pid_path.exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue(child_pid_path.exists())
            child_pid = int(child_pid_path.read_text())

            process.send_signal(signal.SIGTERM)
            process.communicate(timeout=5)
            self.assertNotEqual(process.returncode, 0)
            with self.assertRaises(ProcessLookupError):
                os.kill(child_pid, 0)

    def test_proxy_cancellation_kills_a_group_after_its_leader_exits(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            child_pid_path = root / "child.pid"
            child = (
                "import os,signal,time;"
                "signal.signal(signal.SIGTERM,signal.SIG_IGN);"
                "time.sleep(60)"
            )
            leader = (
                "import subprocess,sys,time;"
                f"child=subprocess.Popen([sys.executable,'-c',{child!r}]);"
                f"open({str(child_pid_path)!r},'w').write(str(child.pid));"
                "time.sleep(60)"
            )
            environment = os.environ.copy()
            environment.update(
                {
                    "BAZEL_EXTERNAL": str(root / "external"),
                    "BAZEL_OUT": str(root / "bazel-out"),
                    "PROJECT_DIR": str(root),
                    "SRCROOT": str(root),
                    "SWIFTBUILD_BAZEL_PROXY_CANCEL_GRACE_SECONDS": "0.1",
                    "SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR": str(root / "request"),
                }
            )
            wrapper = Path(__file__).with_name("process_bazel_build_log.py")
            process = subprocess.Popen(
                [sys.executable, str(wrapper), sys.executable, "-c", leader],
                env=environment,
                stderr=subprocess.PIPE,
                stdout=subprocess.PIPE,
                text=True,
            )
            deadline = time.monotonic() + 5
            while not child_pid_path.exists() and time.monotonic() < deadline:
                time.sleep(0.01)
            self.assertTrue(child_pid_path.exists())
            child_pid = int(child_pid_path.read_text())

            process.send_signal(signal.SIGTERM)
            process.communicate(timeout=5)
            self.assertNotEqual(process.returncode, 0)
            with self.assertRaises(ProcessLookupError):
                os.kill(child_pid, 0)

    def _run_wrapper(self, root, command, action_starts=None):
        environment = os.environ.copy()
        environment.update(
            {
                "BAZEL_EXTERNAL": str(root / "external"),
                "BAZEL_OUT": str(root / "bazel-out"),
                "PROJECT_DIR": str(root),
                "SRCROOT": str(root),
                "SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR": str(root / "request"),
            }
        )
        if action_starts:
            environment["SWIFTBUILD_BAZEL_PROXY_ACTION_STARTS_PATH"] = str(action_starts)
        wrapper = Path(__file__).with_name("process_bazel_build_log.py")
        return subprocess.run(
            [sys.executable, str(wrapper), *command],
            env=environment,
            stderr=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
            timeout=5,
        )


if __name__ == "__main__":
    unittest.main()
