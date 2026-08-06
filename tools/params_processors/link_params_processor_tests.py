"""Tests for link_params_processor."""

import json
import pathlib
import tempfile
import unittest

from tools.params_processors import link_params_processor


class LinkParamsProcessorTest(unittest.TestCase):

    def test_exact_t5_multichunk_fixture_produces_41_line_golden(self):
        testdata = pathlib.Path(__file__).with_name("testdata")
        linkopts = link_params_processor._parse_args([
            str(testdata / "t5-link.sub-0.params"),
            str(testdata / "t5-link.sub-1.params"),
        ])
        self.assertEqual(len(linkopts), 61)
        self.assertEqual(linkopts[:4], [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
        ])

        original_filelist = (
            "bazel-out/ios_sim_arm64-dbg-ios-sim_arm64-min15.0-"
            "ST-3523d915ac13/bin/UI/UIFramework.iOS-intermediates-"
            "ios_sim_arm64/UIFramework.iOS-linker.objlist"
        )
        linkopts[linkopts.index(original_filelist)] = str(
            testdata / "t5-linker.objlist"
        )
        generated_product_paths = json.loads(
            (testdata / "t5-generated-product-paths.json").read_text(
                encoding="utf-8",
            )
        )

        processed = link_params_processor._process_linkopts(
            linkopts=linkopts,
            is_framework=True,
            generated_product_paths=generated_product_paths,
        )
        developer_dir = "/Applications/Xcode-26.5.0.app/Contents/Developer"
        sdkroot = (
            f"{developer_dir}/Platforms/iPhoneSimulator.platform/Developer/"
            "SDKs/iPhoneSimulator26.5.sdk"
        )
        expanded = [
            opt
            .replace("$(DEVELOPER_DIR)", developer_dir)
            .replace("$(SDKROOT)", sdkroot)
            for opt in processed
        ]
        expected = (testdata / "t5-expected-link.params").read_text(
            encoding="utf-8",
        ).splitlines()

        self.assertEqual(len(expected), 41)
        self.assertEqual(expanded, expected)

    def test_parse_args_drops_tool_only_once_across_chunks(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            tool_chunk = root / "sub-0.params"
            args_chunk = root / "sub-1.params"
            tool_chunk.write_text("/path/to/wrapped_clang\n", encoding="utf-8")
            args_chunk.write_text(
                "-Xlinker\n-objc_abi_version\n-Xlinker\n2\n",
                encoding="utf-8",
            )

            self.assertEqual(
                link_params_processor._parse_args([
                    str(tool_chunk),
                    str(args_chunk),
                ]),
                ["-Xlinker", "-objc_abi_version", "-Xlinker", "2"],
            )

    def test_parse_args_expands_redirect_after_tool(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            redirected = root / "redirected.params"
            redirected.write_text("-framework\nSwiftUI\n", encoding="utf-8")
            args_file = root / "args.params"
            args_file.write_text(
                f"/path/to/wrapped_clang\n@{redirected}\n",
                encoding="utf-8",
            )

            self.assertEqual(
                link_params_processor._parse_args([str(args_file)]),
                ["-framework", "SwiftUI"],
            )

    def test_parse_args_expands_first_line_redirect_before_dropping_tool(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            redirected = root / "redirected.params"
            redirected.write_text(
                "/path/to/wrapped_clang\n-Xlinker\n-dead_strip\n",
                encoding="utf-8",
            )
            args_file = root / "args.params"
            args_file.write_text(f"@{redirected}\n", encoding="utf-8")

            self.assertEqual(
                link_params_processor._parse_args([str(args_file)]),
                ["-Xlinker", "-dead_strip"],
            )

    def test_parse_args_rejects_missing_tool(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            args_file = pathlib.Path(temporary_directory) / "args.params"
            args_file.write_text("-Xlinker\n-dead_strip\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "do not contain a tool"):
                link_params_processor._parse_args([str(args_file)])

    def test_parse_args_rejects_empty_input(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            args_file = pathlib.Path(temporary_directory) / "args.params"
            args_file.write_text("", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "do not contain a tool"):
                link_params_processor._parse_args([str(args_file)])

    def test_parse_args_rejects_nested_redirect(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            nested = root / "nested.params"
            nested.write_text("-framework\nSwiftUI\n", encoding="utf-8")
            redirected = root / "redirected.params"
            redirected.write_text(f"@{nested}\n", encoding="utf-8")
            args_file = root / "args.params"
            args_file.write_text(
                f"/path/to/wrapped_clang\n@{redirected}\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Nested.*unsupported"):
                link_params_processor._parse_args([str(args_file)])

    def test_process_linkopts_repairs_preview_driver_grammar(self):
        linkopts = [
            "-Xlinker",
            "-objc_abi_version",
            "-Xlinker",
            "2",
            "LINKED_BINARY=bazel-out/App",
            "DSYM_HINT_LINKED_BINARY=bazel-out/App",
            "-Xlinker",
            "-object_path_lto",
            "-Xlinker",
            "bazel-out/App.lto.o",
            "-F/SDK/System/Library/Frameworks",
        ]

        self.assertEqual(
            link_params_processor._process_linkopts(
                linkopts=linkopts,
                is_framework=True,
                generated_product_paths=[],
            ),
            [
                "-Xlinker",
                "-objc_abi_version",
                "-Xlinker",
                "2",
                "-F/SDK/System/Library/Frameworks",
            ],
        )

    def test_process_linkopts_rejects_malformed_lto_group(self):
        with self.assertRaisesRegex(
            ValueError,
            "Malformed -object_path_lto linker group",
        ):
            link_params_processor._process_linkopts(
                linkopts=[
                    "-Xlinker",
                    "-object_path_lto",
                    "-Xlinker",
                    "-F/SDK/System/Library/Frameworks",
                ],
                is_framework=True,
                generated_product_paths=[],
            )

    def test_process_linkopts_rejects_malformed_abi_group(self):
        with self.assertRaisesRegex(
            ValueError,
            "Malformed -objc_abi_version linker group",
        ):
            link_params_processor._process_linkopts(
                linkopts=["-objc_abi_version", "-Xlinker", "2"],
                is_framework=True,
                generated_product_paths=[],
            )


if __name__ == "__main__":
    unittest.main()
