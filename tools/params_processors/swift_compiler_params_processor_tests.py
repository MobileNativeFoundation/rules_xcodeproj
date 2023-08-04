"""Tests for swift_compiler_params_processor."""

import unittest

from tools.params_processors import swift_compiler_params_processor

class swift_compiler_params_processor_test(unittest.TestCase):
    def test_paths(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_compiler_params_processor.process_args(
                [[
                    "swift_worker",
                    "swiftc",

                    # -fmodule-map-file
                    "-Xcc",
                    "-fmodule-map-file=/absolute/path",
                    "-Xcc",
                    "-fmodule-map-file=relative/path",
                    "-Xcc",
                    "-fmodule-map-file=bazel-out/relative/path",
                    "-Xcc",
                    "-fmodule-map-file=external/relative/path",

                    # -iquote
                    "-Xcc",
                    "-iquote/absolute/path",
                    "-Xcc",
                    "-iquote",
                    "-Xcc",
                    "/absolute/path",
                    "-Xcc",
                    "-iquote",
                    "-Xcc",
                    "/absolute/path",
                    "-Xcc",
                    "-iquoterelative/path",
                    "-Xcc",
                    "-iquote",
                    "-Xcc",
                    "relative/path",
                    "-Xcc",
                    "-iquotebazel-out/relative/path",
                    "-Xcc",
                    "-iquote",
                    "-Xcc",
                    "bazel-out/relative/path",
                    "-Xcc",
                    "-iquoteexternal/relative/path",
                    "-Xcc",
                    "-iquote",
                    "-Xcc",
                    "external/relative/path",
                    "-Xcc",
                    "-iquote.",
                    "-Xcc",
                    "-iquote",
                    "-Xcc",
                    ".",

                    # -I
                    "-I/absolute/path",
                    "-I",
                    "/absolute/path",
                    "-Irelative/path",
                    "-I",
                    "relative/path",
                    "-Ibazel-out/relative/path",
                    "-I",
                    "bazel-out/relative/path",
                    "-Iexternal/relative/path",
                    "-I",
                    "external/relative/path",
                    "-I.",
                    "-I",
                    ".",

                    "-Xcc",
                    "-I/absolute/path",
                    "-Xcc",
                    "-I",
                    "-Xcc",
                    "/absolute/path",
                    "-Xcc",
                    "-Irelative/path",
                    "-Xcc",
                    "-I",
                    "-Xcc",
                    "relative/path",
                    "-Xcc",
                    "-Ibazel-out/relative/path",
                    "-Xcc",
                    "-I",
                    "-Xcc",
                    "bazel-out/relative/path",
                    "-Xcc",
                    "-Iexternal/relative/path",
                    "-Xcc",
                    "-I",
                    "-Xcc",
                    "external/relative/path",
                    "-Xcc",
                    "-I.",
                    "-Xcc",
                    "-I",
                    "-Xcc",
                    ".",

                    # -isystem
                    "-Xcc",
                    "-isystem/absolute/path",
                    "-Xcc",
                    "-isystem",
                    "-Xcc",
                    "/absolute/path",
                    "-Xcc",
                    "-isystemrelative/path",
                    "-Xcc",
                    "-isystem",
                    "-Xcc",
                    "relative/path",
                    "-Xcc",
                    "-isystembazel-out/relative/path",
                    "-Xcc",
                    "-isystem",
                    "-Xcc",
                    "bazel-out/relative/path",
                    "-Xcc",
                    "-isystemexternal/relative/path",
                    "-Xcc",
                    "-isystem",
                    "-Xcc",
                    "external/relative/path",
                    "-Xcc",
                    "-isystem.",
                    "-Xcc",
                    "-isystem",
                    "-Xcc",
                    ".",

                    # -ivfsoverlay
                    "-Xcc",
                    "-ivfsoverlay",
                    "-Xcc",
                    "/Some/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlay",
                    "-Xcc",
                    "relative/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlay",
                    "-Xcc",
                    "bazel-out/relative/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlay",
                    "-Xcc",
                    "external/relative/Path.yaml",

                    "-Xcc",
                    "-ivfsoverlay/Some/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlayrelative/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlaybazel-out/relative/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlayexternal/relative/Path.yaml",

                    "-Xcc",
                    "-ivfsoverlay=/Some/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlay=relative/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlay=bazel-out/relative/Path.yaml",
                    "-Xcc",
                    "-ivfsoverlay=external/relative/Path.yaml",
                ]],
                parse_args = _parse_args,
            ),
            [],
        )

    def test_replacements(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_compiler_params_processor.process_args(
                [[
                    "swift_worker",
                    "swiftc",
                    "-something",
                    "__BAZEL_XCODE_DEVELOPER_DIR__/hi",
                    "-another-thing",
                    "__BAZEL_XCODE_SDKROOT__/path",
                    "-one-more",
                    "__BAZEL_XCODE_SOMETHING_/path",
                ]],
                parse_args = _parse_args,
            ),
            [
                "-something",
                "'$(DEVELOPER_DIR)/hi'",
                "-another-thing",
                "'$(SDKROOT)/path'",
                "-one-more",
                '__BAZEL_XCODE_SOMETHING_/path',
            ],
        )

    def test_skips(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_compiler_params_processor.process_args(
                [[
                    "swift_worker",
                    "swiftc",
                    "-output-file-map",
                    "path",
                    "-passthrough",
                    "-debug-prefix-map",
                    "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
                    "-file-prefix-map",
                    "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
                    "-emit-module-path",
                    "path",
                    "-passthrough",
                    "-Xfrontend",
                    "-color-diagnostics",
                    "-Xfrontend",
                    "-import-underlying-module",
                    "-emit-object",
                    "-enable-batch-mode",
                    "-passthrough",
                    "-gline-tables-only",
                    "-sdk",
                    "something",
                    "-module-name",
                    "name",
                    "-passthrough",
                    "-I__BAZEL_XCODE_SOMETHING_/path",
                    "-num-threads",
                    "6",
                    "-passthrough",
                    "-Ibazel-out/...",
                    "-parse-as-library",
                    "-passthrough",
                    "-parse-as-library",
                    "-keep-me=something.swift",
                    "reject-me.swift",
                    "-target",
                    "ios",
                    "-Xcc",
                    "-weird",
                    "-Xcc",
                    "-a=bazel-out/hi",
                    "-Xwrapped-swift",
                    "-passthrough",
                ]],
                parse_args = _parse_args,
            ),
            [
                "-passthrough",
                "-passthrough",
                "-Xfrontend",
                "-import-underlying-module",
                "-passthrough",
                "-passthrough",
                "-passthrough",
                "-passthrough",
                "-keep-me=something.swift",
                "-passthrough",
            ],
        )

    def test_explicit_swift_module_map_file(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_compiler_params_processor.process_args(
                [[
                    "swift_worker",
                    "swiftc",
                    "-explicit-swift-module-map-file",
                    "/Some/Path.json",
                    "-explicit-swift-module-map-file",
                    "relative/Path.json",
                    "-Xfrontend",
                    "-explicit-swift-module-map-file",
                    "-Xfrontend",
                    "/Some/Path.json",
                    "-Xfrontend",
                    "-explicit-swift-module-map-file",
                    "-Xfrontend",
                    "relative/Path.json",
                ]],
                parse_args = _parse_args,
            ),
            [],
        )

    def test_vfsoverlay(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_compiler_params_processor.process_args(
                [[
                    "swift_worker",
                    "swiftc",
                    "-vfsoverlay",
                    "/Some/Path.yaml",
                    "-vfsoverlay",
                    "relative/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlay",
                    "-Xfrontend",
                    "/Some/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlay",
                    "-Xfrontend",
                    "relative/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlay/Some/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlayrelative/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlay=/Some/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlay=relative/Path.yaml",
                ]],
                parse_args = _parse_args,
            ),
            [],
        )

    def test_quoting(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_compiler_params_processor.process_args(
                [[
                    "swift_worker",
                    "swiftc",
                    "-something",
                    "no_spaces",
                    "-another-thing",
                    "some spaces",
                ]],
                parse_args = _parse_args,
            ),
            [
                "-something",
                "no_spaces",
                "-another-thing",
                "'some spaces'",
            ],
        )

if __name__ == '__main__':
    unittest.main()
