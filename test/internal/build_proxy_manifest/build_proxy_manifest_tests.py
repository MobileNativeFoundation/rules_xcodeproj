import json
import unittest

from xcodeproj.internal import build_proxy_manifest_lib


def _entry(configuration="Debug", arch="arm64"):
    target_id = f"@@//app:app {configuration}-{arch}"
    return {
        "action": "build",
        "bazelLabel": "@@//app:app",
        "configuration": configuration,
        "indexOutputGroups": [f"bc {target_id}", f"bi {target_id}"],
        "outputGroup": f"bp {target_id}",
        "previewOutputGroups": [
            f"bc {target_id}",
            f"bp {target_id}",
            f"bl {target_id}",
        ],
        "product": {
            "basename": "App.app",
            "materialization": "copy_tree",
            "name": "App",
            "path": "bazel-out/App.app",
            "type": "com.apple.product-type.application",
        },
        "targetID": target_id,
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
            bazel_environment_keys=["Z_CUSTOM", "CUSTOM_ENV"],
            generator_label="@@//app:project",
            project_container="App.xcodeproj",
        )
        reverse = build_proxy_manifest_lib.assemble(
            [("b", 1, debug), ("a", 1, release)],
            bazel_path="/usr/local/bin/bazel",
            bazel_environment_keys=["CUSTOM_ENV", "Z_CUSTOM"],
            generator_label="@@//app:project",
            project_container="App.xcodeproj",
        )

        self.assertEqual(forward, reverse)
        manifest = json.loads(forward)
        self.assertEqual(manifest["schemaVersion"], 2)
        self.assertEqual(
            manifest["capabilities"],
            {"actions": ["build", "clean", "indexbuild", "preview"]},
        )
        self.assertEqual(
            manifest["ignoredXcodeTargetGUIDs"],
            ["FF0100000000000000000001"],
        )
        self.assertEqual(
            manifest["invocation"],
            {
                "adapterPath": "rules_xcodeproj/bazel/generate_bazel_dependencies.sh",
                "bazelPath": "/usr/local/bin/bazel",
                "bazelrcPath": "rules_xcodeproj/bazel/xcodeproj.bazelrc",
                "bazelEnvironmentKeys": ["CUSTOM_ENV", "Z_CUSTOM"],
                "environmentKeys": build_proxy_manifest_lib.INVOCATION_ENVIRONMENT_KEYS,
                "generatorLabel": "@@//app:project",
                "receiptSchemaVersion": 1,
            },
        )
        self.assertEqual(
            manifest["project"],
            {"containerName": "App.xcodeproj", "identity": "@@//app:project"},
        )
        self.assertEqual(
            [entry["configuration"] for entry in manifest["targets"]],
            ["Debug", "Release"],
        )

    def test_sensitive_bazel_environment_key_is_rejected(self):
        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "sensitive Bazel environment key",
        ):
            build_proxy_manifest_lib.assemble(
                [],
                bazel_path="bazel",
                bazel_environment_keys=["PRIVATE_TOKEN"],
                generator_label="@@//app:project",
                project_container="App.xcodeproj",
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
                project_container="App.xcodeproj",
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
                project_container="App.xcodeproj",
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
                project_container="App.xcodeproj",
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
                project_container="App.xcodeproj",
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
                project_container="App.xcodeproj",
            )

    def test_product_path_traversal_is_rejected(self):
        entry = _entry()
        entry["product"]["path"] = "bazel-out/../foreign/App.app"

        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "product path must not contain traversal",
        ):
            build_proxy_manifest_lib.assemble(
                [("fragment", 1, _line(entry))],
                bazel_path="bazel",
                generator_label="@@//app:project",
                project_container="App.xcodeproj",
            )

    def test_nested_project_container_records_the_xcodeproj_basename(self):
        contents = build_proxy_manifest_lib.assemble(
            [],
            bazel_path="bazel",
            generator_label="@@//app:project",
            project_container="App/App.xcodeproj",
        )

        self.assertEqual(
            json.loads(contents)["project"]["containerName"],
            "App.xcodeproj",
        )

    def test_project_container_traversal_is_rejected(self):
        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "project container must not contain traversal",
        ):
            build_proxy_manifest_lib.assemble(
                [],
                bazel_path="bazel",
                generator_label="@@//app:project",
                project_container="../App.xcodeproj",
            )

    def test_absolute_project_container_is_rejected(self):
        with self.assertRaisesRegex(
            build_proxy_manifest_lib.ManifestError,
            "project container must be a relative path",
        ):
            build_proxy_manifest_lib.assemble(
                [],
                bazel_path="bazel",
                generator_label="@@//app:project",
                project_container="/tmp/App.xcodeproj",
            )


if __name__ == "__main__":
    unittest.main()
