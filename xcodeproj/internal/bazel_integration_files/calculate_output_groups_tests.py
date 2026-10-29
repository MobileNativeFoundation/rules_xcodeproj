"""Tests for calculate_output_groups."""

import io
import json
import os
import tempfile
import time
import unittest
from unittest import mock

from xcodeproj.internal.bazel_integration_files import calculate_output_groups

_APP_GUID = "app-guid"
_APP_LABEL = "@@//app:App"
_OTHER_GUID = "other-guid"
_GUID_LABELS = {
    _APP_GUID: _APP_LABEL,
    _OTHER_GUID: "@@//other:Other",
}


def _build_request(
        configuration="Debug",
        platform="iphonesimulator",
        guids=(_APP_GUID,)):
    return {
        "configuredTargets": [{"guid": guid} for guid in guids],
        "parameters": {
            "activeRunDestination": {"platform": platform},
            "configurationName": configuration,
        },
    }


class _ObjrootTestCase(unittest.TestCase):

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.objroot = self._tmp.name
        os.makedirs(os.path.join(self.objroot, "XCBuildData"))

        sleep_patcher = mock.patch.object(calculate_output_groups.time, "sleep")
        self.sleep = sleep_patcher.start()
        self.addCleanup(sleep_patcher.stop)

        stderr_patcher = mock.patch("sys.stderr", new_callable=io.StringIO)
        self.stderr = stderr_patcher.start()
        self.addCleanup(stderr_patcher.stop)

    def _xcbuilddata(self, name, contents=None):
        # Each call creates a newer `.xcbuilddata` than the previous one
        path = os.path.join(self.objroot, "XCBuildData", f"{name}.xcbuilddata")
        os.makedirs(path)
        build_request_file = os.path.join(path, "build-request.json")
        if contents is not None:
            with open(build_request_file, "w", encoding="utf-8") as f:
                f.write(contents)
        return build_request_file


class read_build_request_test(_ObjrootTestCase):

    def test_valid_file(self):
        path = self._xcbuilddata("a", json.dumps(_build_request()))
        self.assertEqual(
            calculate_output_groups._read_build_request(path),
            _build_request(),
        )

    def test_missing_file(self):
        path = self._xcbuilddata("a")
        self.assertIsNone(calculate_output_groups._read_build_request(path))

    def test_empty_file(self):
        path = self._xcbuilddata("a", "")
        self.assertIsNone(calculate_output_groups._read_build_request(path))

    def test_truncated_file(self):
        path = self._xcbuilddata("a", json.dumps(_build_request())[:20])
        self.assertIsNone(calculate_output_groups._read_build_request(path))


class get_build_request_test(_ObjrootTestCase):

    def _get_build_request(self, build_request_min_ctime=0):
        return calculate_output_groups._get_build_request(
            xcode_version=1600,
            objroot=self.objroot,
            build_request_min_ctime=build_request_min_ctime,
        )

    def _write_on_sleep(self, path, sleep_count):
        def write(_):
            if self.sleep.call_count == sleep_count:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(json.dumps(_build_request()))
        self.sleep.side_effect = write

    def test_returns_newest_build_request(self):
        self._xcbuilddata("a", json.dumps(_build_request("Old")))
        self._xcbuilddata("b", json.dumps(_build_request("New")))

        self.assertEqual(self._get_build_request(), _build_request("New"))
        self.sleep.assert_not_called()

    def test_waits_while_file_is_empty(self):
        self._write_on_sleep(self._xcbuilddata("a", ""), sleep_count=1)

        self.assertEqual(self._get_build_request(), _build_request())
        self.assertEqual(self.sleep.call_count, 1)

    def test_waits_while_file_is_missing(self):
        self._write_on_sleep(self._xcbuilddata("a"), sleep_count=3)

        self.assertEqual(self._get_build_request(), _build_request())
        self.assertEqual(self.sleep.call_count, 3)

    def test_times_out_when_file_is_never_written(self):
        self._xcbuilddata("a")

        self.assertIsNone(self._get_build_request())
        self.assertEqual(
            self.sleep.call_count,
            calculate_output_groups._BUILD_REQUEST_TIMEOUT_SECONDS,
        )

    def test_times_out_when_newest_is_older_than_marker(self):
        self._xcbuilddata("a", json.dumps(_build_request()))

        self.assertIsNone(
            self._get_build_request(build_request_min_ctime=time.time() + 60),
        )


class find_matching_build_request_test(_ObjrootTestCase):

    def _find(self, scheme_label=_APP_LABEL):
        return calculate_output_groups._find_matching_build_request(
            objroot=self.objroot,
            configuration="Debug",
            platform="iphonesimulator",
            scheme_label=scheme_label,
            guid_labels=_GUID_LABELS,
        )

    def test_skips_newer_without_valid_build_request(self):
        path = self._xcbuilddata("a", json.dumps(_build_request()))
        self._xcbuilddata("b")
        self._xcbuilddata("c", "")

        self.assertEqual(self._find(), (path, _build_request()))

    def test_prefers_newest_match(self):
        self._xcbuilddata("a", json.dumps(_build_request()))
        path = self._xcbuilddata("b", json.dumps(_build_request()))

        self.assertEqual(self._find()[0], path)

    def test_requires_same_configuration(self):
        self._xcbuilddata("a", json.dumps(_build_request("Release")))

        self.assertEqual(self._find(), (None, None))

    def test_requires_same_platform(self):
        self._xcbuilddata("a", json.dumps(_build_request(platform="iphoneos")))

        self.assertEqual(self._find(), (None, None))

    def test_requires_scheme_target(self):
        self._xcbuilddata(
            "a",
            json.dumps(_build_request(guids=(_OTHER_GUID,))),
        )

        self.assertEqual(self._find(), (None, None))

    def test_no_xcbuilddata(self):
        self.assertEqual(self._find(), (None, None))


class get_fallback_build_request_test(_ObjrootTestCase):

    def _get_fallback(self, scheme_label=_APP_LABEL):
        return calculate_output_groups._get_fallback_build_request(
            objroot=self.objroot,
            configuration="Debug",
            platform="iphonesimulator",
            scheme_label=scheme_label,
            guid_labels=_GUID_LABELS,
        )

    def test_returns_match_with_warning(self):
        path = self._xcbuilddata("a", json.dumps(_build_request()))

        self.assertEqual(self._get_fallback(), _build_request())
        self.assertIn("warning:", self.stderr.getvalue())
        self.assertIn(path, self.stderr.getvalue())

    def test_exits_without_match(self):
        self._xcbuilddata("a", json.dumps(_build_request("Release")))

        with self.assertRaises(SystemExit):
            self._get_fallback()
        self.assertIn("error:", self.stderr.getvalue())

    def test_exits_without_scheme_label(self):
        self._xcbuilddata("a", json.dumps(_build_request()))

        with self.assertRaises(SystemExit):
            self._get_fallback(scheme_label="")
        self.assertIn("error:", self.stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
