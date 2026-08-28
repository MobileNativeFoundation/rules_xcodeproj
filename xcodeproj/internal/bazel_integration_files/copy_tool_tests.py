"""Tests for copy_tool."""

import os
import stat
import tempfile
import unittest
from unittest import mock

from xcodeproj.internal.bazel_integration_files import copy_tool


def _write(path, contents="contents"):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(contents)
    return path


def _tree(root):
    # A '/'-separated, sorted listing of every entry under `root`, with a
    # trailing '/' on directories, so trees can be compared in one assert.
    entries = []
    for dirpath, dirnames, filenames in os.walk(root):
        rel_dir = os.path.relpath(dirpath, root)
        prefix = "" if rel_dir == "." else f"{rel_dir}/"
        entries.extend(f"{prefix}{name}/" for name in dirnames)
        entries.extend(f"{prefix}{name}" for name in filenames)
    return sorted(entries)


class compile_pattern_test(unittest.TestCase):

    def test_anchored_pattern(self):
        self.assertEqual(
            copy_tool._Syncer._compile_pattern("/*.app/PlugIns/*.xctest"),
            (["*.app", "PlugIns", "*.xctest"], False),
        )

    def test_recursive_pattern(self):
        self.assertEqual(
            copy_tool._Syncer._compile_pattern("/*.app/PlugIns/***"),
            (["*.app", "PlugIns"], True),
        )

    def test_non_anchored_pattern_raises(self):
        with self.assertRaises(copy_tool.ExcludePatternError):
            copy_tool._Syncer._compile_pattern("*.app/PlugIns")

    def test_cross_directory_wildcard_raises(self):
        with self.assertRaises(copy_tool.ExcludePatternError):
            copy_tool._Syncer._compile_pattern("/*.app/**/PlugIns")


class matches_exclude_test(unittest.TestCase):

    def _syncer(self, *patterns):
        with tempfile.TemporaryDirectory() as tmp:
            exclude_from = _write(
                os.path.join(tmp, "excludes"),
                "".join(f"{p}\n" for p in patterns),
            )
            return copy_tool._Syncer(
                delete=True,
                exclude_from=exclude_from,
                print_copied=False,
            )

    def test_no_rules_matches_nothing(self):
        syncer = self._syncer()
        self.assertFalse(syncer._matches_exclude("Foo.app/PlugIns"))

    def test_exact_match(self):
        syncer = self._syncer("/*.app/PlugIns/*.xctest")
        self.assertTrue(
            syncer._matches_exclude("Foo.app/PlugIns/FooTests.xctest"),
        )
        self.assertFalse(syncer._matches_exclude("Foo.app/PlugIns"))
        self.assertFalse(
            syncer._matches_exclude("Foo.app/PlugIns/FooTests.xctest/Info"),
        )
        self.assertFalse(
            syncer._matches_exclude("Foo.appex/PlugIns/FooTests.xctest"),
        )

    def test_recursive_match(self):
        syncer = self._syncer("/*.app/PlugIns/***")
        self.assertTrue(syncer._matches_exclude("Foo.app/PlugIns"))
        self.assertTrue(syncer._matches_exclude("Foo.app/PlugIns/Deep/File"))
        self.assertFalse(syncer._matches_exclude("Foo.app"))
        self.assertFalse(syncer._matches_exclude("Foo.app/Frameworks"))

    def test_blank_lines_are_ignored(self):
        syncer = self._syncer("", "/*.app/PlugIns/***", "")
        self.assertEqual(len(syncer._exclude_rules), 1)


class main_test(unittest.TestCase):

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.tmp = self._tmp.name
        self.src = os.path.join(self.tmp, "src")
        self.dest = os.path.join(self.tmp, "dest")
        os.makedirs(self.src)
        os.makedirs(self.dest)

    def _excludes(self, *patterns):
        return _write(
            os.path.join(self.tmp, "excludes"),
            "".join(f"{p}\n" for p in patterns),
        )

    def test_copies_bundle_into_dest(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"))
        _write(os.path.join(self.src, "Foo.app/Frameworks/Bar.framework/Bar"))

        copy_tool.main([os.path.join(self.src, "Foo.app"), self.dest])

        self.assertEqual(
            _tree(self.dest),
            [
                "Foo.app/",
                "Foo.app/Frameworks/",
                "Foo.app/Frameworks/Bar.framework/",
                "Foo.app/Frameworks/Bar.framework/Bar",
                "Foo.app/Info.plist",
            ],
        )

    def test_trailing_slash_flattens_contents_into_dest(self):
        _write(os.path.join(self.src, "A.xcscheme"))
        _write(os.path.join(self.src, "nested/B.xcscheme"))

        copy_tool.main([f"{self.src}/", self.dest])

        self.assertEqual(
            _tree(self.dest),
            ["A.xcscheme", "nested/", "nested/B.xcscheme"],
        )

    def test_copies_multiple_srcs(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"))
        _write(os.path.join(self.src, "Foo.app.dSYM/Contents/Info.plist"))

        copy_tool.main([
            os.path.join(self.src, "Foo.app"),
            os.path.join(self.src, "Foo.app.dSYM"),
            self.dest,
        ])

        self.assertEqual(
            _tree(self.dest),
            [
                "Foo.app.dSYM/",
                "Foo.app.dSYM/Contents/",
                "Foo.app.dSYM/Contents/Info.plist",
                "Foo.app/",
                "Foo.app/Info.plist",
            ],
        )

    def test_copied_files_are_user_writable(self):
        src_file = _write(os.path.join(self.src, "Foo.app/Info.plist"))
        os.chmod(src_file, 0o444)

        copy_tool.main([os.path.join(self.src, "Foo.app"), self.dest])

        dest_file = os.path.join(self.dest, "Foo.app/Info.plist")
        self.assertTrue(os.stat(dest_file).st_mode & stat.S_IWUSR)
        self.assertTrue(
            os.stat(os.path.join(self.dest, "Foo.app")).st_mode & stat.S_IWUSR,
        )

    def test_symlinks_are_dereferenced(self):
        target = _write(os.path.join(self.tmp, "target"), "hello")
        os.makedirs(os.path.join(self.src, "Foo.app"))
        os.symlink(target, os.path.join(self.src, "Foo.app/link"))

        copy_tool.main([os.path.join(self.src, "Foo.app"), self.dest])

        dest_file = os.path.join(self.dest, "Foo.app/link")
        self.assertFalse(os.path.islink(dest_file))
        with open(dest_file) as f:
            self.assertEqual(f.read(), "hello")

    def test_overwrites_existing_dest_file(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"), "new")
        _write(os.path.join(self.dest, "Foo.app/Info.plist"), "old")

        copy_tool.main([os.path.join(self.src, "Foo.app"), self.dest])

        with open(os.path.join(self.dest, "Foo.app/Info.plist")) as f:
            self.assertEqual(f.read(), "new")

    def test_replaces_dest_dir_with_src_file(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"), "new")
        _write(os.path.join(self.dest, "Foo.app/Info.plist/nested"), "old")

        copy_tool.main([os.path.join(self.src, "Foo.app"), self.dest])

        dest_file = os.path.join(self.dest, "Foo.app/Info.plist")
        self.assertTrue(os.path.isfile(dest_file))
        with open(dest_file) as f:
            self.assertEqual(f.read(), "new")

    def test_replaces_dest_file_with_src_dir(self):
        _write(os.path.join(self.src, "Foo.app/Frameworks/Bar"))
        _write(os.path.join(self.dest, "Foo.app/Frameworks"), "a file")

        copy_tool.main([os.path.join(self.src, "Foo.app"), self.dest])

        self.assertTrue(
            os.path.isfile(os.path.join(self.dest, "Foo.app/Frameworks/Bar")),
        )

    def test_without_delete_stale_entries_are_kept(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"))
        _write(os.path.join(self.dest, "Foo.app/Stale.plist"))

        copy_tool.main([os.path.join(self.src, "Foo.app"), self.dest])

        self.assertEqual(
            _tree(self.dest),
            ["Foo.app/", "Foo.app/Info.plist", "Foo.app/Stale.plist"],
        )

    def test_delete_removes_stale_entries(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"))
        _write(os.path.join(self.dest, "Foo.app/Stale.plist"))
        _write(os.path.join(self.dest, "Foo.app/Stale/nested"))

        copy_tool.main([
            "--delete",
            os.path.join(self.src, "Foo.app"),
            self.dest,
        ])

        self.assertEqual(
            _tree(self.dest),
            ["Foo.app/", "Foo.app/Info.plist"],
        )

    def test_delete_keeps_excluded_entries(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"))
        _write(os.path.join(self.dest, "Foo.app/PlugIns/Tests.xctest/Tests"))
        _write(os.path.join(self.dest, "Foo.app/Stale.plist"))

        copy_tool.main([
            "--delete",
            f"--exclude-from={self._excludes('/*.app/PlugIns/***')}",
            os.path.join(self.src, "Foo.app"),
            self.dest,
        ])

        self.assertEqual(
            _tree(self.dest),
            [
                "Foo.app/",
                "Foo.app/Info.plist",
                "Foo.app/PlugIns/",
                "Foo.app/PlugIns/Tests.xctest/",
                "Foo.app/PlugIns/Tests.xctest/Tests",
            ],
        )

    def test_print_lists_copied_files(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"))
        _write(os.path.join(self.src, "Foo.app/Frameworks/Bar.framework/Bar"))

        with mock.patch("builtins.print") as mock_print:
            copy_tool.main([
                "--print",
                os.path.join(self.src, "Foo.app"),
                self.dest,
            ])

        self.assertEqual(
            sorted(call.args[0] for call in mock_print.call_args_list),
            [
                "Foo.app/Frameworks/Bar.framework/Bar",
                "Foo.app/Info.plist",
            ],
        )

    def test_no_print_by_default(self):
        _write(os.path.join(self.src, "Foo.app/Info.plist"))

        with mock.patch("builtins.print") as mock_print:
            copy_tool.main([os.path.join(self.src, "Foo.app"), self.dest])

        mock_print.assert_not_called()


if __name__ == "__main__":
    unittest.main()
