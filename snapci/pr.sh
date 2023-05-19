#!/usr/bin/env bash

set -xeuo pipefail

export CI=true

source $(dirname $BASH_SOURCE)/utils.sh

build_and_test
