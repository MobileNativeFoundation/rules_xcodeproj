#!/bin/bash

set -euo pipefail

readonly execution_root="$PROJECT_DIR"

readonly output_base="${execution_root%/*/*}"
readonly build_external="$execution_root/external"

readonly workspace_name="${execution_root##*/}"
readonly index_execution_root="${output_base%/*}/indexbuild_output_base/execroot/$workspace_name"

readonly index_bazel_out="$index_execution_root/bazel-out"
readonly index_external="$index_execution_root/external"

{

# Set `CWD` to `$execution_root` so relative paths in binaries work
#
# This is needed because we use the `oso_prefix_is_pwd` feature, which makes the
# paths to archives relative to the exec root.
echo "platform settings -w \"$execution_root\""

mkdir -p "$index_bazel_out"
mkdir -p "$index_external"

# "Undo" `-debug-prefix-map` for breakpoints
#
# This needs to cause the files to match exactly what Xcode set for breakpoints,
# which is why we don't use `$execution_root` here. Xcode will set the path
# based on the way you opened a file. If you open a file via the Project
# navigator, or indexing (e.g. Jump to Definition), it will use the paths
# specified below.

# `bazel-out` when set from Project navigator or swiftsourcefile
echo "settings set target.source-map ./bazel-out/ \"$BAZEL_OUT\""
# `bazel-out` when set from indexing opened file
echo "settings append target.source-map ./bazel-out/ \"$index_bazel_out\""

# `external` when set from Project navigator
echo "settings append target.source-map ./external/ \"$BAZEL_EXTERNAL\""
# `external` when set from indexing opened file
echo "settings append target.source-map ./external/ \"$index_external\""
# `external` when set from swiftsourcefile
echo "settings append target.source-map ./external/ \"$build_external\""

# Project files and locally resolved external repositories
#
# lldb seems to match breakpoints based on the second argument, using a simple
# prefix check that doesn't take into account the trailing slash. This means
# that we have to order the source-map settings so that the longest paths are
# first, otherwise an earlier setting can prevent a later setting from matching.
if [[ -n "${RESOLVED_REPOSITORIES:-}" ]]; then
  # `external` for local repositories when set from Project navigator,
  # and the project root
  while IFS='' read -r x; do repos+=("$x"); done < <(xargs -n1 <<< "$RESOLVED_REPOSITORIES")
  for (( i=0; i<${#repos[@]}; i+=2 )); do
    prefix="${repos[$i]}"
    path="${repos[$i+1]}"
    echo "settings append target.source-map \"$prefix/\" \"$path\""
  done
fi

# Import swift_debug_settings.py
#
# This Python module sets a stop hook, that when hit, sets the Swift debug
# settings (i.e. `target.swift-*``) for the module of the current frame. This
# fixes debugging when using `-serialize-debugging-options`.
echo "command script import \"$OBJROOT/$CONFIGURATION/swift_debug_settings.py\""

} > "$BAZEL_LLDB_INIT"

if  [[ -f "$HOME/.lldbinit-Xcode" ]]; then
  readonly lldbinit="$HOME/.lldbinit-Xcode"
elif [[ -f "$HOME/.lldbinit" ]]; then
  readonly lldbinit="$HOME/.lldbinit"
else
  readonly lldbinit="$HOME/.lldbinit-Xcode"
fi

touch "$lldbinit"

readonly required_source='command source ~/.lldbinit-rules_xcodeproj'
if ! grep -m 1 -q "^$required_source$" "$lldbinit"; then
  # Add a newline if the file doesn't end with one
  tail -c 1 "$lldbinit" | read || echo >> "$lldbinit"
  # Update `$lldbinit to source `~/.lldbinit-rules_xcodeproj`
  echo "$required_source" >> "$lldbinit"
fi
