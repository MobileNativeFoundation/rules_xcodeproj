#!/usr/bin/python3

# Copies one or more source trees into a destination directory, optionally
# deleting destination entries that no longer exist in the source (mirroring
# `rsync --delete`), while leaving alone any destination entries that match
# an exclude pattern (mirroring `rsync --exclude-from`). Symlinks encountered
# while walking the source are dereferenced, copying the content they point
# to (mirroring `rsync --copy-links`).
#
# When running against APFS volumes on macOS the 'clonefile' system call will
# be used to copy files without consuming additional disk space.
#

import argparse
import errno
import fnmatch
import os
import shutil
import sys
from ctypes import CDLL, c_char_p, c_int, get_errno

_CLONEFILE = None
_USE_CLONEFILE = sys.platform == "darwin"
def _load_clonefile():
  global _CLONEFILE
  if _CLONEFILE:
    return _CLONEFILE

  system = CDLL('/usr/lib/libSystem.dylib', use_errno=True)
  _CLONEFILE = system.clonefile
  _CLONEFILE.argtypes = [c_char_p, c_char_p, c_int] # src, dest, flags
  _CLONEFILE.restype = c_int  # 0 on success
  return _CLONEFILE


def _copy_file(src, dest):
    # clonefile does not overwrite dest if it already exists.
    if os.path.lexists(dest):
        if os.path.isdir(dest) and not os.path.islink(dest):
            shutil.rmtree(dest)
        else:
            os.remove(dest)

    global _USE_CLONEFILE
    if _USE_CLONEFILE:
        clonefile = _load_clonefile()
        result = clonefile(src.encode(), dest.encode(), 0)

        if result != 0:
            # Recover fom `EXDEV` (cross-device) and `ENOTSUP` (destination
            # filesystem doesn't support cloning) by disabling clonefile and
            # falling back to copy2.
            if get_errno() in (errno.EXDEV, errno.ENOTSUP):
                _USE_CLONEFILE = False
                shutil.copy2(src, dest)
            else:
                raise Exception(f"failed to clonefile {src} to {dest}")
    else:
        shutil.copy2(src, dest)


def _chmod(path):
    # Add user writable flag
    mode = os.stat(path).st_mode | 0o200
    os.chmod(path, mode)


class _Syncer:
    def __init__(self, delete, exclude_from, print_copied):
        self.delete = delete
        self.print_copied = print_copied
        self._exclude_rules = [
            self._compile_pattern(p) for p in self._read_exclude_patterns(exclude_from)
        ]

    @staticmethod
    def _read_exclude_patterns(path):
        # Break exclude file into a list of non-empty lines.
        if not path:
            return []
        with open(path) as f:
            return [line.strip("\n") for line in f if line.strip("\n")]

    @staticmethod
    def _compile_pattern(pattern):
        # Convert an rsync exclude path into a list of path segments to
        # match against, and a boolean indicating if the pattern should
        # match recursively or not.
        #
        # Non-anchored patterns (not starting with a leading '/') and
        # cross-directory wildcards within paths (/Base/**/child)
        # aren't supported and will raise an exception.
        if not pattern.startswith("/"):
            raise ValueError(
                f"Exclude pattern {pattern!r} does not start with '/'. "
                "This tool only supports rsync's anchored pattern form "
                " with a leading '/'"
            )
        pattern = pattern.strip("/")

        if pattern.endswith("/***"):
            # A trailing "/***" is rsync's shorthand for "this directory and
            # everything under it. Capture the base path and set 'recursive'
            # to 'True'.
            base_segments, recursive = pattern[: -len("/***")].split("/"), True
        else:
            base_segments, recursive = pattern.split("/"), False

        # Cross-directory wildcards are not supported outside of '***' above.
        if any("**" in segment for segment in base_segments):
            raise ValueError(
                f"Exclude pattern {pattern!r} contains '**' outside of a "
                "trailing '/***'. This tool doesn't implement rsync's "
                "cross-directory '**' wildcard."
            )

        return base_segments, recursive

    def _matches_exclude(self, rel_path):
        segments = rel_path.split("/")

        for base_segments, recursive in self._exclude_rules:
            if recursive:
                if len(segments) < len(base_segments):
                    # `rel_path` is shorter than the path prefix, so it
                    # can't possibly be inside it.
                    continue

                # Compare up to base_segments length for a match
                to_compare = segments[: len(base_segments)]
            else:
                # Non-recursive pattern can't match if they're not the
                # same length.
                if len(segments) != len(base_segments):
                    continue
                to_compare = segments

            if all(fnmatch.fnmatchcase(s, p) for s, p in zip(to_compare, base_segments)):
                return True

        # None of the rules matched.
        return False

    def sync_tree(self, src_dir, dest_dir, rel_prefix):
        # Walks `src_dir` and `dest_dir` together, one directory level at
        # a time, to copy the content of src_dir into dest_dir. If `delete`
        # is set files only in `dest_dir` will be deleted unless they match
        # `_exclude_rules`.

        # Delete dest_dir if it is a file or a symlink.
        if os.path.isfile(dest_dir) or os.path.islink(dest_dir):
            os.remove(dest_dir)

        # Create dest_dir if it doesn't exist. Permissions and other stats
        # are updated at the bottom of the function once the content has
        # been populated/updated.
        os.makedirs(dest_dir, exist_ok=True)

        src_names = set(os.listdir(src_dir))
        dest_names = set(os.listdir(dest_dir))

        if self.delete:
            # Names present in `dest_dir` but not in `src_dir` are stale
            for name in dest_names - src_names:
                rel_path = f"{rel_prefix}/{name}" if rel_prefix else name
                if self._matches_exclude(rel_path):
                    continue

                dest_path = os.path.join(dest_dir, name)
                if os.path.isdir(dest_path) and not os.path.islink(dest_path):
                    shutil.rmtree(dest_path)
                else:
                    os.remove(dest_path)

        for name in src_names:
            src_path = os.path.join(src_dir, name)
            dest_path = os.path.join(dest_dir, name)
            rel_path = f"{rel_prefix}/{name}" if rel_prefix else name

            if os.path.isdir(src_path):
                # Recursively call sync_tree to clone child directories
                self.sync_tree(src_path, dest_path, rel_path)
            else:
                _copy_file(src_path, dest_path)
                _chmod(dest_path)
                if self.print_copied:
                    print(rel_path)

        # Fix dest_dir's permissions and properties now that copying is done.
        shutil.copystat(src_dir, dest_dir)
        _chmod(dest_dir)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--delete", action="store_true")
    parser.add_argument("--exclude-from", default=None)
    parser.add_argument("--print", action="store_true", dest="print_copied")
    parser.add_argument("srcs", nargs="+")
    parser.add_argument("dest")
    args = parser.parse_args()

    syncer = _Syncer(args.delete, args.exclude_from, args.print_copied)

    for src in args.srcs:
        flatten = src.endswith("/")
        src = src.rstrip("/")

        rel_prefix = "" if flatten else os.path.basename(src)
        dest_root = os.path.join(args.dest, rel_prefix) if rel_prefix else args.dest

        syncer.sync_tree(src, dest_root, rel_prefix)


if __name__ == "__main__":
    main()
