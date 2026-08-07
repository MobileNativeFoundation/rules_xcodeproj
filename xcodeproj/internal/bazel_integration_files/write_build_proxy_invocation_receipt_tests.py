import json
import stat
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from xcodeproj.internal.bazel_integration_files import write_build_proxy_invocation_receipt


class WriteBuildProxyInvocationReceiptTests(unittest.TestCase):
    def test_writes_redacted_private_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "receipt.json"
            arguments = [
                "writer",
                str(output),
                "--working-directory=/workspace",
                "--command=build",
                "--startup-option=--output_base=/tmp/output",
                "--bazelrc=/workspace/generated.bazelrc",
                "--command-option=--config=_rules_xcodeproj_build",
                "--target=//app:project",
                "--label=//app:app",
                "--output-group=bp //app:app ios-sim",
                "--target-id=//app:app ios-sim",
                "--environment-key=DEVELOPER_DIR",
                "--mode=config=_rules_xcodeproj_build",
                "--materialization=contract=manifest-v2",
                "--bep-path=/private/build-event.jsonl",
            ]
            with mock.patch("sys.argv", arguments):
                write_build_proxy_invocation_receipt.main()

            receipt = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(receipt["schemaVersion"], 1)
            self.assertEqual(receipt["environmentKeys"], ["DEVELOPER_DIR"])
            self.assertNotIn("environment", receipt)
            self.assertEqual(receipt["provenance"]["bepPath"], "/private/build-event.jsonl")
            self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o600)

    def test_rejects_credential_bearing_option(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "receipt.json"
            arguments = [
                "writer",
                str(output),
                "--working-directory=/workspace",
                "--command=build",
                "--command-option=--remote_header=authorization:secret",
            ]
            with mock.patch("sys.argv", arguments):
                with self.assertRaisesRegex(ValueError, "credential-bearing"):
                    write_build_proxy_invocation_receipt.main()
            self.assertFalse(output.exists())

    def test_rejects_secret_repo_environment_option(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "receipt.json"
            arguments = [
                "writer",
                str(output),
                "--working-directory=/workspace",
                "--command=build",
                "--command-option=--repo_env=PRIVATE_API_KEY=do-not-record",
            ]
            with mock.patch("sys.argv", arguments):
                with self.assertRaisesRegex(ValueError, "credential-bearing"):
                    write_build_proxy_invocation_receipt.main()
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
