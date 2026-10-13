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

    def test_selected_library_option_groups_are_removed_atomically(self):
        selected = "bazel-out/bin/libSelected.a"
        dependency = "external/dependency/libDependency.a"
        for option in (
            "-force_load", "-reexport_library", "-weak_library",
            "-needed_library", "-upward_library", "-load_hidden",
        ):
            for spelling in ("plain", "forwarded", "comma"):
                def group(path):
                    if spelling == "plain":
                        return [option, path]
                    if spelling == "forwarded":
                        return ["-Xlinker", option, "-Xlinker", path]
                    return ["-Wl," + option + "," + path]

                with self.subTest(option=option, spelling=spelling):
                    retained = group(dependency) + ["-framework", "SwiftUI"]
                    self.assertEqual(
                        link_params_processor._process_linkopts(
                            group(selected) + retained, False, [selected],
                        ),
                        link_params_processor._process_linkopts(
                            retained, False, [],
                        ),
                    )

    def test_selected_library_binding_options_are_removed_atomically(self):
        selected = "bazel-out/bin/libSelected.a"
        dependency = "external/dependency/libDependency.a"
        for option in (
            "-lazy_library", "-delay_library", "-assert_weak_library",
        ):
            for spelling in ("plain", "forwarded", "comma"):
                def group(path):
                    if spelling == "plain":
                        return [option, path]
                    if spelling == "forwarded":
                        return ["-Xlinker", option, "-Xlinker", path]
                    return ["-Wl," + option + "," + path]

                with self.subTest(option=option, spelling=spelling):
                    retained = group(dependency) + ["-framework", "Foundation"]
                    self.assertEqual(
                        link_params_processor._process_linkopts(
                            group(selected) + retained, False, [selected],
                        ),
                        link_params_processor._process_linkopts(
                            retained, False, [],
                        ),
                    )

    def test_selected_forwarded_input_does_not_leave_xlinker(self):
        selected = "bazel-out/bin/libSelected.a"
        self.assertEqual(
            link_params_processor._process_linkopts(
                ["-Xlinker", selected, "-framework", "SwiftUI"],
                False, [selected],
            ),
            ["-framework", "SwiftUI"],
        )

    def test_comma_group_keeps_options_around_selected_library(self):
        selected = "bazel-out/bin/libSelected.a"
        self.assertEqual(
            link_params_processor._process_linkopts(
                ["-Wl,-dead_strip,-force_load," + selected + ",-no_deduplicate"],
                False, [selected],
            ),
            ["-Wl,-dead_strip,-no_deduplicate"],
        )

    def test_selected_product_matching_is_exact(self):
        for selected in ("bazel-out/bin/libSelected.a", "/absolute/libSelected.a"):
            inputs = ["external/prefix/" + selected, selected + ".other.a"]
            with self.subTest(selected=selected):
                self.assertEqual(
                    link_params_processor._process_linkopts(
                        [selected, "'" + selected + "'"] + inputs,
                        False, [selected],
                    ),
                    link_params_processor._process_linkopts(inputs, False, []),
                )

    def test_matching_non_library_values_are_not_removed(self):
        selected = "bazel-out/bin/libSelected.a"
        for linkopts in (
            ["-install_name", selected],
            ["-Xlinker", "-install_name", "-Xlinker", selected],
            ["-Wl,-install_name," + selected],
            ["-Wl,-sectcreate,__DATA,__blob," + selected],
            ["-Xlinker", "-sectcreate", "-Xlinker", "__DATA",
             "-Xlinker", "__blob", "-Xlinker", selected],
        ):
            with self.subTest(linkopts=linkopts):
                self.assertEqual(
                    link_params_processor._process_linkopts(linkopts, False, [selected]),
                    link_params_processor._process_linkopts(linkopts, False, []),
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
