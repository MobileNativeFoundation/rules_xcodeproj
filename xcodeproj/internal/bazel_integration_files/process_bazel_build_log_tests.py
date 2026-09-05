import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest


class ProcessBazelBuildLogTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
