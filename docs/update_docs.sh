#!/bin/bash

set -euo pipefail

bazel run --config=cache //docs:update
