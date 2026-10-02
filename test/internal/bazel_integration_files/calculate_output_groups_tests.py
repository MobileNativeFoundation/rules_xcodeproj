import builtins
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock


_SCRIPT = Path(__file__).parents[3] / (
    "xcodeproj/internal/bazel_integration_files/calculate_output_groups.py"
)
_SPEC = importlib.util.spec_from_file_location("calculate_output_groups", _SCRIPT)
calculate_output_groups = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(calculate_output_groups)


class BuildRequestPublicationTests(unittest.TestCase):
    def setUp(self):
        temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(temporary_directory.cleanup)
        self.objroot = Path(temporary_directory.name)
        self.cache = self.objroot / "XCBuildData"
        self.cache.mkdir()
        self.request = {"parameters": {"configurationName": "Debug"}}

    def request_path(self, xcode_version):
        if xcode_version < 1430:
            request_id = "1234567890abcdef1234567890abcdef"
            (self.cache / "BuildDescriptionCacheIndex-test").write_bytes(
                b"cache prefix" + request_id.encode("ascii")
            )
            return self.cache / f"{request_id}-buildRequest.json"
        directory = self.cache / "current.xcbuilddata"
        directory.mkdir(exist_ok=True)
        return directory / "build-request.json"

    def read_request(self, xcode_version):
        return calculate_output_groups._get_build_request(
            xcode_version, str(self.objroot), 0
        )

    def test_valid_request_has_no_retry_delay(self):
        for version in (1420, 2660):
            with self.subTest(xcode_version=version):
                self.request_path(version).write_text(json.dumps(self.request))
                with mock.patch.object(
                    calculate_output_groups.time, "sleep"
                ) as sleep:
                    self.assertEqual(self.read_request(version), self.request)
                sleep.assert_not_called()

    def test_partial_request_becomes_valid(self):
        for version in (1420, 2660):
            for partial in ("", '{"parameters":'):
                with self.subTest(xcode_version=version, partial=partial):
                    path = self.request_path(version)
                    path.write_text(partial)

                    def publish(_delay):
                        path.write_text(json.dumps(self.request))

                    with mock.patch.object(
                        calculate_output_groups.time, "sleep", side_effect=publish
                    ) as sleep:
                        self.assertEqual(self.read_request(version), self.request)
                    sleep.assert_called_once_with(0.1)

    def test_request_becomes_valid_on_last_allowed_attempt(self):
        for version in (1420, 2660):
            with self.subTest(xcode_version=version):
                path = self.request_path(version)
                path.write_text("")
                sleep_count = 0

                def publish(_delay):
                    nonlocal sleep_count
                    sleep_count += 1
                    if sleep_count == 9:
                        path.write_text(json.dumps(self.request))

                with mock.patch.object(
                    calculate_output_groups.time, "sleep", side_effect=publish
                ) as sleep:
                    self.assertEqual(self.read_request(version), self.request)
                self.assertEqual(sleep.call_args_list, [mock.call(0.1)] * 9)

    def test_permanently_malformed_request_fails_after_bounded_retries(self):
        for version in (1420, 2660):
            with self.subTest(xcode_version=version):
                path = self.request_path(version)
                path.write_text("not JSON")
                errors = io.StringIO()
                with mock.patch.object(
                    calculate_output_groups.time, "sleep"
                ) as sleep:
                    with contextlib.redirect_stderr(errors):
                        with self.assertRaises(SystemExit) as result:
                            self.read_request(version)
                self.assertEqual(result.exception.code, 1)
                self.assertEqual(sleep.call_args_list, [mock.call(0.1)] * 9)
                self.assertIn("Failed to parse", errors.getvalue())
                self.assertIn("JSONDecodeError", errors.getvalue())
                self.assertIn(str(path), errors.getvalue())

    def test_invalid_encoding_is_not_retried(self):
        for version in (1420, 2660):
            with self.subTest(xcode_version=version):
                self.request_path(version).write_bytes(b"\xff")
                errors = io.StringIO()
                with mock.patch.object(
                    calculate_output_groups.time, "sleep"
                ) as sleep:
                    with contextlib.redirect_stderr(errors):
                        with self.assertRaises(SystemExit):
                            self.read_request(version)
                sleep.assert_not_called()
                self.assertIn("UnicodeDecodeError", errors.getvalue())

    def test_request_disappearing_before_open_is_rediscovered(self):
        path = self.request_path(2660)
        path.write_text(json.dumps(self.request))
        removed = False

        def open_request(filename, *args, **kwargs):
            nonlocal removed
            if not removed:
                removed = True
                path.unlink()
                path.parent.rmdir()
                raise FileNotFoundError(filename)
            return builtins.open(filename, *args, **kwargs)

        def publish(_delay):
            directory = self.cache / "replacement.xcbuilddata"
            directory.mkdir()
            (directory / "build-request.json").write_text(json.dumps(self.request))

        with mock.patch.object(
            calculate_output_groups, "open", side_effect=open_request, create=True
        ):
            with mock.patch.object(
                calculate_output_groups.time, "sleep", side_effect=publish
            ) as sleep:
                with contextlib.redirect_stderr(io.StringIO()):
                    self.assertEqual(self.read_request(2660), self.request)
        sleep.assert_called_once_with(1)


if __name__ == "__main__":
    unittest.main()
