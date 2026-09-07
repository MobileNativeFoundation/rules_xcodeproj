"""Tests for link_params_processor."""

import json
import pathlib
import tempfile
import unittest

from tools.params_processors import link_params_processor


class LinkParamsProcessorTest(unittest.TestCase):

    def test_process_linkopts_preserves_quoted_absolute_and_dyld_paths(self):
        self.assertEqual(
            link_params_processor._process_linkopts(
                linkopts=["/absolute/With Spaces/lib.a", "-Wl,-rpath,@loader_path/With Spaces"],
                is_framework=False,
                generated_product_paths=[],
            ),
            ["'/absolute/With Spaces/lib.a'", "'-Wl,-rpath,@loader_path/With Spaces'"],
        )

    def test_xcode_owned_entitlements_do_not_retain_bazel_artifacts(self):
        self.assertEqual(
            link_params_processor._process_linkopts(
                linkopts=[
                    "-Wl,-sectcreate,__TEXT,__entitlements,bazel-out/App.xcent",
                    "-Wl,-sectcreate,__TEXT,__ents_der,bazel-out/App.der",
                    "-ObjC",
                ],
                is_framework=False,
                generated_product_paths=[],
            ),
            ["-ObjC"],
        )

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

    def test_parse_args_preserves_loader_paths_in_all_supported_layouts(self):
        linkopts = [
            "-Xlinker", "-install_name", "-Xlinker",
            "@rpath/Dependency With Spaces.framework/Dependency With Spaces",
            "-Xlinker", "-rpath", "-Xlinker", "@loader_path/Frameworks",
            "-Xlinker", "-rpath", "-Xlinker", "@executable_path/Frameworks",
            "-Xlinker", "-rpath", "-Xlinker", "@loader_path",
            "-Xlinker", "-rpath", "-Xlinker", "@executable_path",
        ]
        tool = "/path/to/wrapped_clang"
        for layout in ("direct", "redirect-after-tool", "redirect-with-tool"):
            with self.subTest(layout=layout):
                with tempfile.TemporaryDirectory() as temporary_directory:
                    root = pathlib.Path(temporary_directory)
                    args_file = root / "args.params"
                    arguments = [tool] + linkopts
                    if layout != "direct":
                        redirected = root / "redirected.params"
                        response_args = (
                            arguments if layout == "redirect-with-tool"
                            else linkopts
                        )
                        redirected.write_text(
                            "\n".join(response_args) + "\n",
                            encoding="utf-8",
                        )
                        arguments = (
                            [tool] if layout == "redirect-after-tool" else []
                        ) + [f"@{redirected}"]
                    args_file.write_text(
                        "\n".join(arguments) + "\n", encoding="utf-8",
                    )

                    self.assertEqual(
                        link_params_processor._parse_args([str(args_file)]),
                        linkopts,
                    )

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
