"""Tests for link_params_processor."""

import pathlib
import shlex
import tempfile
import unittest

from tools.params_processors import link_params_processor


class LinkParamsProcessorTest(unittest.TestCase):

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
                    str(tool_chunk), str(args_chunk),
                ]),
                ["-Xlinker", "-objc_abi_version", "-Xlinker", "2"],
            )

    def test_parse_args_expands_redirects_and_preserves_dyld_paths(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            redirected = root / "redirected.params"
            redirected.write_text(
                "-framework\nSwiftUI\n@rpath/Foo.framework/Foo\n"
                "@loader_path/Frameworks\n@executable_path/Frameworks\n",
                encoding="utf-8",
            )
            args_file = root / "args.params"
            args_file.write_text(
                f"/path/to/wrapped_clang\n@{redirected}\n",
                encoding="utf-8",
            )

            self.assertEqual(
                link_params_processor._parse_args([str(args_file)]),
                ["-framework", "SwiftUI", "@rpath/Foo.framework/Foo",
                 "@loader_path/Frameworks", "@executable_path/Frameworks"],
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

    def test_parse_args_rejects_missing_tool_and_nested_redirect(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = pathlib.Path(temporary_directory)
            args_file = root / "args.params"
            args_file.write_text("-Xlinker\n-dead_strip\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "do not contain a tool"):
                link_params_processor._parse_args([str(args_file)])

            nested = root / "nested.params"
            nested.write_text("-framework\nSwiftUI\n", encoding="utf-8")
            redirected = root / "redirected.params"
            redirected.write_text(f"@{nested}\n", encoding="utf-8")
            args_file.write_text(
                f"/path/to/wrapped_clang\n@{redirected}\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "Nested.*unsupported"):
                link_params_processor._parse_args([str(args_file)])

    def test_response_quoting_preserves_special_characters(self):
        for path in (
            "external/Author's Library/libDependency.a",
            'external/Double "quotes"/libDependency.a',
            "external/back\\slash/libDependency.a",
            "external/tab\tdirectory/libDependency.a",
        ):
            with self.subTest(path=path):
                self.assertEqual(
                    shlex.split(link_params_processor._quote_if_needed(path)),
                    [path],
                )

    def test_bazel_shell_quoted_inputs_are_decoded_before_processing(self):
        selected = "bazel-out/Author's Target/libSelected.a"
        dependency = "external/Author's Library/libDependency.a"
        processed = link_params_processor._process_linkopts(
            ["-force_load", shlex.quote(selected), shlex.quote(dependency)],
            False, [selected],
        )
        self.assertEqual(
            shlex.split("\n".join(processed)),
            [dependency],
        )

    def test_bundle_does_not_consume_following_linker_option(self):
        self.assertEqual(
            link_params_processor._process_linkopts(
                ["-bundle", "-ObjC", "-framework", "Foundation"],
                is_framework = False,
                generated_product_paths = [],
            ),
            ["-ObjC", "-framework", "Foundation"],
        )


if __name__ == "__main__":
    unittest.main()
