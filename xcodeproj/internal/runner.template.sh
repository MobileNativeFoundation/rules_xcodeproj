#!/bin/bash

set -euo pipefail


# Functions

# Echos the provided message to stderr and exits with an error (1)
fail() {
  local msg="${1:-}"
  shift 1
  while (("$#")); do
    msg="${msg:-}"$'\n'"${1}"
    shift 1
  done
  echo >&2 "${msg}"
  exit 1
}

# Process Args

readonly bazelrc="$PWD/%bazelrc%"
readonly extra_flags_bazelrc="$PWD/%extra_flags_bazelrc%"

installer_flags=(--extra_flags_bazelrc "$extra_flags_bazelrc")

while (("$#")); do
  case "${1}" in
    "--build_output_groups")
      build_output_groups="${2}"
      shift 2
      ;;
    "--destination")
      installer_flags+=(--destination "${2}")
      shift 2
      ;;
    *)
      fail "Unrecognized argument: ${1}"
      ;;
  esac
done

cd "$BUILD_WORKSPACE_DIRECTORY"

bazelrcs=(
  --noworkspace_rc
  "--bazelrc=$bazelrc"
)
if [[ -s ".bazelrc" ]]; then
  bazelrcs+=("--bazelrc=.bazelrc")
fi
if [[ -s "$extra_flags_bazelrc" ]]; then
  bazelrcs+=("--bazelrc=$extra_flags_bazelrc")
fi

if [[ -z "${build_output_groups:-}" ]]; then
  echo 'Generating "%project_name%.xcodeproj"'

  "%bazel_path%" \
    "${bazelrcs[@]}" \
    run \
    --config=rules_xcodeproj_generator \
    %extra_generator_flags% \
    "%generator_label%" \
    -- "${installer_flags[@]}"
else
  echo "Building \"%generator_label% --output_groups=$build_output_groups\""

  "%bazel_path%" \
    "${bazelrcs[@]}" \
    build \
    --config=rules_xcodeproj_build \
    --output_groups="$build_output_groups" \
    "%generator_label%"
fi
