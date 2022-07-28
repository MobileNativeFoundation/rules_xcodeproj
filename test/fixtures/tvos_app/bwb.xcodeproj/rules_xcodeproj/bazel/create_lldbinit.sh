#!/bin/bash

set -euo pipefail

readonly exec_root="$1"

readonly output_base="${exec_root%/*/*}"
readonly build_bazel_out="$exec_root/bazel-out"
readonly build_external="$output_base/external"

readonly index_objroot="${OBJROOT%/Build/Intermediates.noindex}/Index/Build/Intermediates.noindex"
readonly workspace_name="${exec_root##*/}"
readonly index_exec_root="$index_objroot/bazel_output_base/execroot/$workspace_name"

readonly index_bazel_out="$index_exec_root/bazel-out"
readonly index_external="$index_exec_root/external"

# Load ~/.lldbinit if it exists
if [[ -f "$HOME/.lldbinit" ]]; then
  echo "command source ~/.lldbinit"
fi

# Set `CWD` to `$exec_root` so relative paths in binaries work
#
# This is needed because we use the `oso_prefix_is_pwd` feature, which makes the
# paths to archives relative to the exec root.
echo "platform settings -w \"$exec_root\""

mkdir -p "$index_bazel_out"
mkdir -p "$index_external"

# "Undo" `-debug-prefix-map` for breakpoints
#
# This needs to cause the files to match exactly what Xcode set for breakpoints,
# which is why we don't use `$exec_root` here. Xcode will set the path based
# on the way you opened a file. If you open a file via the Project navigator,
# or indexing (e.g. Jump to Definition), it will use the paths specified below.

# Generated when set from Project navigator
echo "settings set target.source-map ./bazel-out/ \"$GEN_DIR\""
# Generated when set from indexing opened file
echo "settings append target.source-map ./bazel-out/ \"$index_bazel_out\""
# Generated when set from swiftsourcefile
echo "settings append target.source-map ./external/ \"$build_bazel_out\""

# External when set from Project navigator
echo "settings append target.source-map ./external/ \"$BAZEL_EXTERNAL\""
# External when set from indexing opened file
echo "settings append target.source-map ./external/ \"$index_external\""
# External when set from swiftsourcefile
echo "settings append target.source-map ./external/ \"$build_external\""

# Project files
echo "settings append target.source-map ./ \"$SRCROOT\""

# Import swift_debug_settings.py
#
# This Python module sets a stop hook, that when hit, sets the Swift debug
# settings (i.e. `target.swift-*``) for the module of the current frame. This
# fixes debugging when using `-serialize-debugging-options`.
echo "command script import \"$BUILD_DIR/swift_debug_settings.py\""
