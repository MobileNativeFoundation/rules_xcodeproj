#!/bin/bash

# This is a test script that simulates a custom Swift compiler
# It will be used as an override in the custom toolchain

# Print inputs for debugging
echo "Custom swiftc called with args: $@" >&2

# In a real override, you would do something meaningful with the args
# For testing, just exit successfully
exit 0
