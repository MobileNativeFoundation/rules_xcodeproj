#!/bin/bash

set -euo pipefail

readonly exec_root="$1"

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
# it will use the paths specified below.
echo "settings set target.source-map ./bazel-out/ \"$GEN_DIR\""
echo "settings append target.source-map ./external/ \"$BAZEL_EXTERNAL\""
echo "settings append target.source-map ./ \"$SRCROOT\""
