#!/bin/bash

readonly output="$1"
shift

echo "import Foundation" > "$output"
cat "$@" >> "$output"
