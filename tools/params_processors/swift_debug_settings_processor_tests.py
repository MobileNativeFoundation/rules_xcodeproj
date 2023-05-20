"""Tests for swift_debug_settings_processor."""

import unittest

from tools.params_processors import swift_debug_settings_processor


def _before_each(seq, element):
    return [
        y
        for x in seq
        for y in (element, x)
    ]


class swift_debug_settings_processor_test(unittest.TestCase):

    def test_paths(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_debug_settings_processor.process_swift_params(
                [[
                    "swiftc",

                    # -fmodule-map-file
                    *_before_each(
                        [
                            "-fmodule-map-file=/absolute/path",
                            "-fmodule-map-file=relative/path",
                            "-fmodule-map-file=.",
                        ],
                        "-Xcc",
                    ),

                    # -iquote
                    "-iquote/absolute/path",
                    "-iquote",
                    "/absolute/path",
                    "-iquote",
                    "/absolute/path",
                    "-iquoterelative/path",
                    "-iquote",
                    "relative/path",
                    "-iquote.",
                    "-iquote",
                    ".",

                    *_before_each(
                        [
                            "-iquote/absolute/path",
                            "-iquote",
                            "/absolute/path",
                            "-iquote",
                            "/absolute/path",
                            "-iquoterelative/path",
                            "-iquote",
                            "relative/path",
                            "-iquote.",
                            "-iquote",
                            ".",
                        ],
                        "-Xcc",
                    ),

                    # -I
                    "-I/absolute/path",
                    "-I",
                    "/absolute/path",
                    "-Irelative/path",
                    "-I",
                    "relative/path",
                    "-I.",
                    "-I",
                    ".",

                    *_before_each(
                        [
                            "-I/absolute/path",
                            "-I",
                            "/absolute/path",
                            "-Irelative/path",
                            "-I",
                            "relative/path",
                            "-I.",
                            "-I",
                            ".",
                        ],
                        "-Xcc",
                    ),

                    # -isystem
                    "-isystem/absolute/path",
                    "-isystem",
                    "/absolute/path",
                    "-isystemrelative/path",
                    "-isystem",
                    "relative/path",
                    "-isystem.",
                    "-isystem",
                    ".",

                    *_before_each(
                        [
                            "-isystem/absolute/path",
                            "-isystem",
                            "/absolute/path",
                            "-isystemrelative/path",
                            "-isystem",
                            "relative/path",
                            "-isystem.",
                            "-isystem",
                            ".",
                        ],
                        "-Xcc",
                    ),
                ]],
                parse_args = _parse_args,
            ),
            [
                # -fmodule-map-file
                "-fmodule-map-file=/absolute/path",
                "-fmodule-map-file=$(PROJECT_DIR)/relative/path",
                "-fmodule-map-file=$(PROJECT_DIR)",

                # -iquote
                "-iquote/absolute/path",
                "-iquote",
                "/absolute/path",
                "-iquote",
                "/absolute/path",
                "-iquote$(PROJECT_DIR)/relative/path",
                "-iquote",
                "$(PROJECT_DIR)/relative/path",
                "-iquote$(PROJECT_DIR)",
                "-iquote",
                "$(PROJECT_DIR)",

                # -I
                "-I/absolute/path",
                "-I",
                "/absolute/path",
                "-I$(PROJECT_DIR)/relative/path",
                "-I",
                "$(PROJECT_DIR)/relative/path",
                "-I$(PROJECT_DIR)",
                "-I",
                "$(PROJECT_DIR)",

                # -isystem
                "-isystem/absolute/path",
                "-isystem",
                "/absolute/path",
                "-isystem$(PROJECT_DIR)/relative/path",
                "-isystem",
                "$(PROJECT_DIR)/relative/path",
                "-isystem$(PROJECT_DIR)",
                "-isystem",
                "$(PROJECT_DIR)",
            ],
        )

    def test_replacements(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_debug_settings_processor.process_swift_params(
                [[
                    "swiftc",

                    *_before_each(
                        [
                            "-F__BAZEL_XCODE_DEVELOPER_DIR__/Hi",
                            "-I__BAZEL_XCODE_SDKROOT__/Yo",
                            "-I__BAZEL_XCODE_SOMETHING_/path",
                        ],
                        "-Xcc",
                    )
                ]],
                parse_args = _parse_args,
            ),
            [
                "-F$(DEVELOPER_DIR)/Hi",
                "-I$(SDKROOT)/Yo",
                "-I__BAZEL_XCODE_SOMETHING_/path",
            ],
        )

    def test_vfsoverlay(self):
        def _parse_args(args):
            return iter([f"{arg}\n" for arg in args])

        self.assertEqual(
            swift_debug_settings_processor.process_swift_params(
                [[
                    "swiftc",

                    "-vfsoverlay",
                    "/skipped/Some/Path.yaml",
                    "-vfsoverlay",
                    "skipped/relative/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlay",
                    "-Xfrontend",
                    "/skipped/Some/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlay",
                    "-Xfrontend",
                    "skipped/relative/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlay/skipped/Some/Path.yaml",
                    "-Xfrontend",
                    "-vfsoverlayskipped/relative/Path.yaml",

                    *_before_each(
                        [
                            "-ivfsoverlay",
                            "/Some/Path.yaml",
                            "-ivfsoverlay",
                            "relative/Path.yaml",
                            "-ivfsoverlay",
                            "/Some/Path.yaml",
                            "-ivfsoverlay",
                            "relative/Path.yaml",
                            "-ivfsoverlay/Some/Path.yaml",
                            "-ivfsoverlayrelative/Path.yaml",
                        ],
                        "-Xcc",
                    )
                ]],
                parse_args = _parse_args,
            ),
            [
                "-ivfsoverlay",
                "/Some/Path.yaml",
                "-ivfsoverlay",
                "$(CURRENT_EXECUTION_ROOT)/relative/Path.yaml",
                "-ivfsoverlay",
                "/Some/Path.yaml",
                "-ivfsoverlay",
                "$(CURRENT_EXECUTION_ROOT)/relative/Path.yaml",
                "-ivfsoverlay/Some/Path.yaml",
                "-ivfsoverlay$(CURRENT_EXECUTION_ROOT)/relative/Path.yaml",
            ],
        )

if __name__ == '__main__':
    unittest.main()
