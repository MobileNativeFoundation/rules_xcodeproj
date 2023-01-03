#!/bin/bash

set -euo pipefail

# Set version
echo "5.4.0" > "$BUILD_WORKSPACE_DIRECTORY/.bazelversion"
