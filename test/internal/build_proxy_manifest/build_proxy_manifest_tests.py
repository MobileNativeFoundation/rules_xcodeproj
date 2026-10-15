import json
import unittest

from xcodeproj.internal import build_proxy_manifest_lib


def _entry(configuration="Debug", arch="arm64"):
    return {
        "action": "build",
        "bazelLabel": "@@//app:app",
        "configuration": configuration,
        "outputGroup": f"bp @@//app:app {configuration}-{arch}",
        "product": {
            "basename": "App.app",
            "name": "App",
            "path": "bazel-out/App.app",
            "type": "com.apple.product-type.application",
        },
        "targetID": f"@@//app:app {configuration}-{arch}",
        "variant": {
            "arch": arch,
            "minimumOSVersion": "18.0",
            "platform": "iphonesimulator",
        },
        "xcodeTargetGUID": "0000AAAAAAAA000000000001",
    }


def _line(entry):
    return json.dumps(entry, separators=(",", ":"), sort_keys=True)


class BuildProxyManifestTests(unittest.TestCase):
    def test_assemble_is_versioned_and_byte_deterministic(self):
        debug = _line(_entry())
        release = _line(_entry(configuration="Release"))

        forward = build_proxy_manifest_lib.assemble(
            [("a", 1, release), ("b", 1, debug)],
            bazel_path="/usr/local/bin/bazel",
            generator_label="@@//app:project",
        )
        reverse = build_proxy_manifest_lib.assemble(
            [("b", 1, debug), ("a", 1, release)],
            bazel_path="/usr/local/bin/bazel",
            generator_label="@@//app:project",
        )

        self.assertEqual(forward, reverse)
        manifest = json.loads(forward)
        self.assertEqual(manifest["schemaVersion"], 1)
        self.assertEqual(manifest["capabilities"], {"actions": ["build"]})
        self.assertEqual(
            manifest["ignoredXcodeTargetGUIDs"],
            ["FF0100000000000000000001"],
        )
        self.assertEqual(
            manifest["invocation"],
            {
                "bazelPath": "/usr/local/bin/bazel",
                "bazelrcPath": "rules_xcodeproj/bazel/xcodeproj.bazelrc",
                "generatorLabel": "@@//app:project",
            },
        )
        self.assertEqual(
            [entry["configuration"] for entry in manifest["targets"]],
            ["Debug", "Release"],
        )

    def test_missing_required_key_is_rejected(self):
        entry = _entry()
        del entry["xcodeTargetGUID"]

        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "missing keys: xcodeTargetGUID",
        ):
            build_proxy_manifest_lib.assemble(
                [("fragment", 1, _line(entry))],
                bazel_path="bazel",
                generator_label="@@//app:project",
            )

    def test_unsupported_action_is_rejected(self):
        entry = _entry()
        entry["action"] = "archive"

        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "unsupported action: 'archive'",
        ):
            build_proxy_manifest_lib.assemble(
                [("fragment", 1, _line(entry))],
                bazel_path="bazel",
                generator_label="@@//app:project",
            )

    def test_duplicate_mapping_is_rejected(self):
        entry = _line(_entry())

        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "duplicate target mapping",
        ):
            build_proxy_manifest_lib.assemble(
                [("fragment", 1, entry), ("fragment", 2, entry)],
                bazel_path="bazel",
                generator_label="@@//app:project",
            )

    def test_missing_generator_label_is_rejected(self):
        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "generator label must not be empty",
        ):
            build_proxy_manifest_lib.assemble(
                [],
                bazel_path="bazel",
                generator_label="",
            )

    def test_missing_bazel_path_is_rejected(self):
        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "Bazel path must not be empty",
        ):
            build_proxy_manifest_lib.assemble(
                [],
                bazel_path="",
                generator_label="@@//app:project",
            )


if __name__ == "__main__":
    unittest.main()
