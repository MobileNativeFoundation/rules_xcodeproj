#!/bin/bash

set -euo pipefail

readonly exec_root="$1"

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

# "Undo" `-debug-prefix-map` for breakpoints
#
# This needs to cause the files to match exactly what Xcode set for breakpoints,
# which is why we don't use `$exec_root` here. Xcode will set the path based
# on the way you opened a file. If you open a file via the Project navigator,
# or indexing (e.g. Jump to Definition), it will use the paths specified below.
echo "settings set target.source-map ./bazel-out/ \"$GEN_DIR\""
echo "settings append target.source-map ./bazel-out/ \"$index_bazel_out\""
echo "settings append target.source-map ./external/ \"$BAZEL_EXTERNAL\""
echo "settings append target.source-map ./external/ \"$index_external\""
echo "settings append target.source-map ./ \"$SRCROOT\""
