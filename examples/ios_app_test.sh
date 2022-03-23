#!/usr/bin/env bash

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---

# MARK - Locate Deps

assertions_sh_location=cgrindel_bazel_starlib/shlib/lib/assertions.sh
assertions_sh="$(rlocation "${assertions_sh_location}")" || \
  (echo >&2 "Failed to locate ${assertions_sh_location}" && exit 1)
source "${assertions_sh}"


# MARK - Process Arguments

bazel="${BIT_BAZEL_BINARY:-}"
workspace_dir="${BIT_WORKSPACE_DIR:-}"
bazel_configs=()

while (("$#")); do
  case "${1}" in
    "--config")
      bazel_configs+=( "${2}" )
      shift 2
      ;;
    *)
      fail "Unrecognized argument. ${1}"
      ;;
  esac
done

[[ -n "${bazel:-}" ]] || fail "Must specify the location of the Bazel binary."
[[ -n "${workspace_dir:-}" ]] || fail "Must specify the location of the workspace directory."

bazel_cmd_opts=()
if [[ ${#bazel_configs[@]} -gt 0 ]]; then
  for config in "${bazel_configs[@]}" ; do
    bazel_cmd_opts+=( "--config=${config}" )
  done
fi


# MARK - Test

exec_bazel_cmd() {
  local cmd="${1}"
  shift 1
  local bazel_cmd=( "${cmd}" )
  [[ ${#bazel_cmd_opts[@]} -gt 0 ]] && bazel_cmd+=( "${bazel_cmd_opts[@]}" )
  [[ ${#} -gt 0 ]] && bazel_cmd+=( "${@}" )
  "${bazel_cmd[@]}"
}

fail "IMPLEMENT ME!"
