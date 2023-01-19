#!/bin/bash

set -euo pipefail

bazel run --config=cache --noexperimental_enable_bzlmod //docs:update
