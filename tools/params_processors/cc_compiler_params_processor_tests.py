"""Tests for cc_compiler_params_processor."""

import unittest

from tools.params_processors import cc_compiler_params_processor

class cc_compiler_params_processor_test(unittest.TestCase):

    def test_skips(self):
        def _parse_args(args):
            return [f"{arg}\n" for arg in args]

        self.assertEqual(
            cc_compiler_params_processor.process_args(
                [[
                    "clang",
                    "-mtvos-simulator-version-min=8.0",
                    "-passthrough",
                    "-isysroot",
                    "other",
                    "-mios-simulator-version-min=11.2",
                    "-miphoneos-version-min=9.0",
                    "-passthrough",
                    "-mtvos-version-min=12.1",
                    "-I__BAZEL_XCODE_SOMETHING_/path",
                    "-mwatchos-simulator-version-min=10.1",
                    "-passthrough",
                    "-mwatchos-version-min=9.2",
                    "-target",
                    "ios",
                    "-mmacosx-version-min=12.0",
                    "-passthrough",
                    "-index-store-path",
                    "bazel-out/_global_index_store",
                    "-index-ignore-system-symbols",
                ]],
                _parse_args,
            ),
            [
                "-passthrough",
                "-passthrough",
                "-I__BAZEL_XCODE_SOMETHING_/path",
                "-passthrough",
                "-passthrough",
            ],
        )

    def test_quoting(self):
        def _parse_args(args):
            return [f"{arg}\n" for arg in args]

        self.assertEqual(
            cc_compiler_params_processor.process_args(
                [[
                    "clang",
                    "-Inon/quoted/path",
                    "--config",
                    "relative/Path.yaml",
                    "-DFOO=\"Bar\"",
                ]],
                _parse_args,
            ),
            [
                "-Inon/quoted/path",
                "--config",
                "'$(PROJECT_DIR)/relative/Path.yaml'",
                "'-DFOO=\"Bar\"'",
            ],
        )

if __name__ == '__main__':
    unittest.main()
