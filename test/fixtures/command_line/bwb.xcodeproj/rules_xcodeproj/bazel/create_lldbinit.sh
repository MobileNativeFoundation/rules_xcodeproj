#!/bin/bash

set -euo pipefail

readonly external="$1"

# Load ~/.lldbinit if it exists
if [[ -f "$HOME/.lldbinit" ]]; then
  echo "command source ~/.lldbinit"
fi

# Set `CWD` to `$SRCROOT` so relative paths in binaries work
echo "platform settings -w \"$SRCROOT\""

# "Undo" `-debug-prefix-map`
echo "settings set target.source-map ./external/ \"$external\""
echo "settings append target.source-map ./ \"$SRCROOT\""
