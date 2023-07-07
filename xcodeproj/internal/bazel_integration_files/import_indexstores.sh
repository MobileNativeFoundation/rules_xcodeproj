#!/bin/bash

set -euo pipefail

readonly pidfile="$OBJROOT/import_indexstores.pid"
readonly execution_root="$1"
shift

# Kill previously running import
if [[ -s "$pidfile" ]]; then
  pid=$(cat "$pidfile")
  kill "$pid" 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null; do
    sleep 1
  done
fi

# Exit early if no indexstore filelists were provided
if [ $# -eq 0 ]; then
  exit
fi

# Set pid to allow cleanup later
echo $$ > "$pidfile"
trap 'rm "$pidfile" 2>/dev/null || true' EXIT

# Merge all filelists into a single file
filelist="$(mktemp)"
sort -u "$@" | sed "s|^|$execution_root/|" > "$filelist"

# Exit early if no indexstores were provided
if [ ! -s "$filelist" ]; then
  exit
fi

# Set remaps

# We only support importing indexes built with rules_xcodeproj, and we override
# our output bases, so we know the the ending of the execution root
readonly execution_root_regex='.*/[^/]+/(?:_)?rules_xcodeproj(?:\.noindex)?/[^/]+_output_base/execroot/[^/]+'

# We remove any `/private` prefix from the current execution_root, since it's
# removed in the Project navigator.
readonly xcode_execution_root="${execution_root#/private}"

if [[ "$RULES_XCODEPROJ_BUILD_MODE" == "xcode" && \
      "$XCODE_VERSION_ACTUAL" -gt "1330" ]]
then
  # In BwX mode, Xcode 13.3+ uses `-index-unit-output-path` to create hermetic
  # object file paths. We need to remap the same way to get unit file hash
  # matches.
  readonly object_file_prefix="/${PROJECT_TEMP_DIR##*/}"
else
  # Remove SwiftUI Previews part of path
  readonly object_file_prefix="${PROJECT_TEMP_DIR/\/Intermediates.noindex\/Previews\/*\/Intermediates.noindex\///Intermediates.noindex/}"
fi

# The order of remaps is important. The first match is used. So we try the most
# specific first. This also allows us to assume previous matches have taken care
# of those types of files, so more general matches still work later.
remaps=(
  # Object files
  #
  # These currently come back relative, but we have the execution_root as an
  # optional prefix in case this changes in the future. The path is based on
  # rules_swift's current logic:
  # https://github.com/bazelbuild/rules_swift/blob/6153a848f747e90248a8673869c49631f1323ff3/swift/internal/derived_files.bzl#L114-L119
  # When we add support for C-based index imports we will have to use another
  # pattern:
  # https://github.com/bazelbuild/bazel/blob/c4a1ab8b6577c4376aaaa5c3c2d4ef07d524175c/src/main/java/com/google/devtools/build/lib/rules/cpp/CcCompilationHelper.java#L1358
  -remap "^(?:$execution_root_regex/|\./)?(bazel-out/[^/]+/bin/)(?:_swift_incremental/)?(.*?)([^/]+)_objs/.*?([^/]+?)(?:\.swift)?\.o\$=$object_file_prefix/\$1\$2\$3/Objects-normal/${ARCHS%% *}/\$4.o"

  # Generated sources and swiftmodules
  #
  # With object files taken care of, any other paths with `bazel-out/` as their
  # prefix (relative to the execution_root) are assumed to be generated outputs.
  # The two kinds of generated outputs used in the unit files are swiftmodule
  # and source paths. So we map that, along with the `external/` prefix for
  # external sources, to the current execution_root. Finally, currently these
  # paths are returned as absolute, but a future change might make them
  # relative, similar to the object files, so we have the execution_root as an
  # optional prefix.
  -remap "^(?:$execution_root_regex/|\./)?bazel-out/=$xcode_execution_root/bazel-out/"

  # External sources
  #
  # External sources need to be handled differently, since we use the
  # non-symlinked version in Xcode.
  -remap "^(?:$execution_root_regex/|\./)?external/=${xcode_execution_root%/*/*}/external/"

  # Project sources
  #
  # With the other source files and generated files taken care of, all other
  # execution_root prefixed paths should be project sources.
  -remap "^$execution_root_regex=$SRCROOT"

  # Sysroot
  #
  # The only other type of path in the unit files are sysroot based. While
  # these should always be Xcode.app relative, our regex supports command-line
  # tools based paths as well.
  # `DEVELOPER_DIR` has an optional `./` prefix, because index-import adds `./`
  # to all relative paths.
  -remap "^(?:.*?/[^/]+/Contents/Developer|(?:./)?DEVELOPER_DIR|/PLACEHOLDER_DEVELOPER_DIR|/Library/Developer/CommandLineTools).*?/SDKs/([^\\d.]+)=$DEVELOPER_DIR/Platforms/\$1.platform/Developer/SDKs/\$1"
)

# Import

mkdir -p "$INDEX_DATA_STORE_DIR"

"$INDEX_IMPORT" \
    -undo-rules_swift-renames \
    "${remaps[@]}" \
    -incremental \
    @"$filelist" \
    "$INDEX_DATA_STORE_DIR"

rm "$filelist"

# Unit files are created fresh, but record files are copied from `bazel-out/`,
# which are read-only. We need to adjust their permissions.
# TODO: Do this in `index-import`
chmod -R u+w "$INDEX_DATA_STORE_DIR"
