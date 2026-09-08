"""Tests for link_params_processor."""

import json
import pathlib
import shlex
import tempfile
import unittest

from tools.params_processors import link_params_processor


class LinkParamsProcessorTest(unittest.TestCase):

    def test_anchor_to_execution_root_only_rewrites_relative_paths(self):
        for value, expected in [
            (
                "external/swiftpkg/libDependency.a",
                "'$(PROJECT_DIR)/external/swiftpkg/libDependency.a'",
            ),
            ("libDependency.a", "'$(PROJECT_DIR)/libDependency.a'"),
            (
                "-Fexternal/swiftpkg/Dependency.framework",
                "'-F$(PROJECT_DIR)/external/swiftpkg/Dependency.framework'",
            ),
            ("-FFrameworks", "'-F$(PROJECT_DIR)/Frameworks'"),
            (
                "-Lexternal/swiftpkg/lib",
                "'-L$(PROJECT_DIR)/external/swiftpkg/lib'",
            ),
            ("-Llib", "'-L$(PROJECT_DIR)/lib'"),
            (
                "-Wl,-add_ast_path,bazel-out/Dependency.swiftmodule",
                "'-Wl,-add_ast_path,$(PROJECT_DIR)/bazel-out/Dependency.swiftmodule'",
            ),
            (
                "-Wl,-force_load,external/swiftpkg/libDependency.a",
                "'-Wl,-force_load,$(PROJECT_DIR)/external/swiftpkg/libDependency.a'",
            ),
            (
                "-Wl,-force_load,libDependency.a",
                "'-Wl,-force_load,$(PROJECT_DIR)/libDependency.a'",
            ),
            (
                "-Wl,-order_file,external/swiftpkg/order.txt",
                "'-Wl,-order_file,$(PROJECT_DIR)/external/swiftpkg/order.txt'",
            ),
            (
                "-Wl,-filelist,external/swiftpkg/objects.list",
                "'-Wl,-filelist,$(PROJECT_DIR)/external/swiftpkg/objects.list'",
            ),
            (
                "-Wl,-filelist,objects.list,external/swiftpkg",
                "'-Wl,-filelist,$(PROJECT_DIR)/objects.list,"
                "$(PROJECT_DIR)/external/swiftpkg'",
            ),
            (
                "-Wl,-exported_symbols_list,external/swiftpkg/exports.txt",
                "'-Wl,-exported_symbols_list,$(PROJECT_DIR)/external/swiftpkg/"
                "exports.txt'",
            ),
            (
                "-Wl,-sectcreate,__DATA,__blob,external/blob.bin",
                "'-Wl,-sectcreate,__DATA,__blob,$(PROJECT_DIR)/external/blob.bin'",
            ),
            (
                "-Wl,-load_hidden,libDependency.a",
                "'-Wl,-load_hidden,$(PROJECT_DIR)/libDependency.a'",
            ),
            ("/absolute/libDependency.a", "/absolute/libDependency.a"),
            ("@response.params", "@response.params"),
            ("-F/absolute/Frameworks", "-F/absolute/Frameworks"),
            ("-L$(PROJECT_DIR)/external/lib", "'-L$(PROJECT_DIR)/external/lib'"),
            (
                "-Wl,-rpath,@loader_path/Frameworks",
                "-Wl,-rpath,@loader_path/Frameworks",
            ),
            ("-Wl,-install_name,relative/Foo", "-Wl,-install_name,relative/Foo"),
            (
                "$(SDKROOT)/System/Library/Frameworks",
                "'$(SDKROOT)/System/Library/Frameworks'",
            ),
            ("-framework", "-framework"),
            ("Lottie", "Lottie"),
        ]:
            with self.subTest(value=value):
                self.assertEqual(
                    link_params_processor._anchor_to_execution_root(value),
                    expected,
                )

    def test_xcode_owns_xml_and_der_entitlement_sections(self):
        self.assertEqual(
            link_params_processor._process_linkopts(
                linkopts=[
                    "-Wl,-sectcreate,__TEXT,__entitlements,bazel-out/App.xcent",
                    "-Wl,-sectcreate,__TEXT,__ents_der,bazel-out/App.der",
                    "-Wl,-sectcreate,__DATA,__blob,external/blob.bin",
                    "-ObjC",
                ],
                is_framework=False,
                generated_product_paths=[],
            ),
            ["'-Wl,-sectcreate,__DATA,__blob,$(PROJECT_DIR)/external/blob.bin'", "-ObjC"],
        )

    def test_process_linkopts_anchors_force_loaded_external_archive(self):
        self.assertEqual(
            link_params_processor._process_linkopts(
                linkopts=[
                    "-force_load",
                    "external/swiftpkg/libDependency.a",
                    "-framework",
                    "Lottie",
                ],
                is_framework=True,
                generated_product_paths=[],
            ),
            [
                "-force_load",
                "'$(PROJECT_DIR)/external/swiftpkg/libDependency.a'",
                "-framework",
                "Lottie",
            ],
        )

    def test_process_linkopts_preserves_split_relative_install_name(self):
        self.assertEqual(
            link_params_processor._process_linkopts(
                linkopts=[
                    "-Xlinker",
                    "-install_name",
                    "-Xlinker",
                    "relative/Foo",
                    "-Xlinker",
                    "-force_load",
                    "-Xlinker",
                    "libDependency.a",
                ],
                is_framework=True,
                generated_product_paths=[],
            ),
            [
                "-Xlinker",
                "-install_name",
                "-Xlinker",
                "relative/Foo",
                "-Xlinker",
                "-force_load",
                "-Xlinker",
                "'$(PROJECT_DIR)/libDependency.a'",
            ],
        )

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

    def test_process_linkopts_preserves_quoted_absolute_and_dyld_paths(self):
        self.assertEqual(
            link_params_processor._process_linkopts(
                linkopts=["/absolute/With Spaces/lib.a", "-Wl,-rpath,@loader_path/With Spaces"],
                is_framework=False,
                generated_product_paths=[],
            ),
            ["'/absolute/With Spaces/lib.a'", "'-Wl,-rpath,@loader_path/With Spaces'"],
        )

    def test_anchored_response_arguments_preserve_spaces_after_expansion(self):
        # The root can contain spaces even when the serialized relative path
        # does not. Exercise direct, split, joined, and positional path forms.
        for project_dir in ("/execution-root", "/execution root"):
            for relative_dir in ("external/dependency", "external/my dependency"):
                archive = relative_dir + "/libDependency.a"
                cases = [
                    ([archive], [f"{project_dir}/{archive}"]),
                    ([f"'{archive}'"], [f"{project_dir}/{archive}"]),
                    (["-L" + relative_dir], [f"-L{project_dir}/{relative_dir}"]),
                    (["-F" + relative_dir], [f"-F{project_dir}/{relative_dir}"]),
                    (["-Xlinker", "-force_load", "-Xlinker", archive],
                     ["-Xlinker", "-force_load", "-Xlinker", f"{project_dir}/{archive}"]),
                    (["-Wl,-force_load," + archive],
                     [f"-Wl,-force_load,{project_dir}/{archive}"]),
                    (["-Wl,-sectcreate,__DATA,__blob," + relative_dir + "/blob"],
                     [f"-Wl,-sectcreate,__DATA,__blob,{project_dir}/{relative_dir}/blob"]),
                    (["-Wl,-filelist,objects.list," + relative_dir],
                     [f"-Wl,-filelist,{project_dir}/objects.list,{project_dir}/{relative_dir}"]),
                ]
                for linkopts, expected in cases:
                    with self.subTest(project_dir=project_dir, linkopts=linkopts):
                        processed = link_params_processor._process_linkopts(
                            linkopts, False, [],
                        )
                        response = "\n".join(processed).replace(
                            "$(PROJECT_DIR)", project_dir,
                        )
                        self.assertEqual(shlex.split(response), expected)

    def test_filelist_paths_preserve_spaces_after_expansion(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            filelist = pathlib.Path(temporary_directory) / "objects.list"
            filelist.write_text(
                "external/my dependency/libDependency.a\n"
                "bazel-out/selected.a\n"
                "bazel-out/selected.o\n",
                encoding="utf-8",
            )
            processed = link_params_processor._process_linkopts(
                ["-filelist", str(filelist)], False, ["bazel-out/selected.a"],
            )
            response = "\n".join(processed).replace(
                "$(PROJECT_DIR)", "/execution root",
            )
            self.assertEqual(shlex.split(response), [
                "/execution root/external/my dependency/libDependency.a",
            ])

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
