#!/bin/bash

set -euo pipefail

fail() {
  echo >&2 "rules_xcodeproj build proxy launcher: ${1}"
  exit 1
}

sha256_file() {
  local file="$1"
  local output

  if command -v sha256sum > /dev/null 2>&1; then
    output="$(sha256sum -- "$file")" || fail "SHA-256 calculation failed for $file"
  elif command -v shasum > /dev/null 2>&1; then
    output="$(shasum -a 256 -- "$file")" || fail "SHA-256 calculation failed for $file"
  else
    fail "neither sha256sum nor shasum is available"
  fi

  local digest="${output%%[[:space:]]*}"
  digest="$(printf '%s' "$digest" | tr '[:upper:]' '[:lower:]')"
  if [[ ! "$digest" =~ ^[0-9a-f]{64}$ ]]; then
    fail "SHA-256 tool returned malformed output for $file"
  fi
  printf '%s\n' "$digest"
}

read_single_line() {
  local file="$1"
  local description="$2"
  local value

  [[ -f "$file" && ! -L "$file" ]] || fail "$description is missing or symbolic: $file"
  value="$(<"$file")"
  [[ -n "$value" && "$value" != *$'\n'* && "$value" != *$'\r'* ]] || \
    fail "$description is empty or malformed: $file"
  printf '%s\n' "$value"
}

launch_xcode() {
  local open_path="$1"
  local selected_xcode_application="$2"
  local selected_project="$3"
  shift 3

  local open_arguments=("$@")
  if ((${#open_arguments[@]} == 0)); then
    open_arguments=("$selected_project")
  fi

  "$open_path" \
    -n \
    -F \
    --env "XCBBUILDSERVICE_PATH=$XCBBUILDSERVICE_PATH" \
    --env "DEVELOPER_DIR=$DEVELOPER_DIR" \
    --env "SWIFTBUILD_BAZEL_PROXY_MANIFEST=$SWIFTBUILD_BAZEL_PROXY_MANIFEST" \
    --env "SWIFTBUILD_BAZEL_PROXY_MANIFEST_SHA256=$SWIFTBUILD_BAZEL_PROXY_MANIFEST_SHA256" \
    --env "SWIFTBUILD_BAZEL_PROXY_PROJECT_IDENTITY=$SWIFTBUILD_BAZEL_PROXY_PROJECT_IDENTITY" \
    -a "$selected_xcode_application" \
    "${open_arguments[@]}"
}

main() {
  if (($# == 0)); then
    fail "usage: $0 xcode [open arguments] | xcodebuild [arguments]"
  fi

  local mode="$1"
  shift
  [[ "$mode" == "xcode" || "$mode" == "xcodebuild" ]] || \
    fail "unsupported mode '$mode'; expected xcode or xcodebuild"

  local launcher_directory
  launcher_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  local project
  project="$(cd "$launcher_directory/../.." && pwd -P)"
  local proxy="$launcher_directory/build_service_proxy"
  local manifest="$project/rules_xcodeproj/bazel/build_proxy_manifest.json"

  [[ -f "$proxy" && ! -L "$proxy" && -x "$proxy" ]] || \
    fail "installed proxy is missing, symbolic, or not executable: $proxy"
  [[ -f "$manifest" && ! -L "$manifest" ]] || \
    fail "schema-v2 build-proxy manifest is missing or symbolic: $manifest"

  local expected_proxy_sha256
  expected_proxy_sha256="$(read_single_line \
    "$launcher_directory/build_service_proxy.sha256" \
    "proxy SHA-256")"
  [[ "$expected_proxy_sha256" =~ ^[0-9a-f]{64}$ ]] || \
    fail "proxy SHA-256 is not a lowercase 64-character digest"

  local expected_manifest_sha256
  expected_manifest_sha256="$(read_single_line \
    "$launcher_directory/build_proxy_manifest.sha256" \
    "manifest SHA-256")"
  [[ "$expected_manifest_sha256" =~ ^[0-9a-f]{64}$ ]] || \
    fail "manifest SHA-256 is not a lowercase 64-character digest"

  local project_identity
  project_identity="$(read_single_line \
    "$launcher_directory/project_identity" \
    "project identity")"

  local actual_proxy_sha256
  actual_proxy_sha256="$(sha256_file "$proxy")"
  [[ "$actual_proxy_sha256" == "$expected_proxy_sha256" ]] || \
    fail "proxy SHA-256 mismatch: expected $expected_proxy_sha256, got $actual_proxy_sha256"

  local actual_manifest_sha256
  actual_manifest_sha256="$(sha256_file "$manifest")"
  [[ "$actual_manifest_sha256" == "$expected_manifest_sha256" ]] || \
    fail "manifest SHA-256 mismatch: expected $expected_manifest_sha256, got $actual_manifest_sha256"

  local native_service
  if ! native_service="$("$proxy" --resolve-native-service)"; then
    fail "proxy compatibility check failed for the selected Xcode"
  fi
  [[ -n "$native_service" && "$native_service" != *$'\n'* && \
     "$native_service" == /*/Contents/* ]] || \
    fail "proxy returned an invalid native build service path"
  [[ -x "$native_service" && ! -L "$native_service" ]] || \
    fail "proxy returned a missing, symbolic, or non-executable native build service: $native_service"

  local xcode_application="${native_service%%/Contents/*}"
  local developer_directory="$xcode_application/Contents/Developer"
  local xcode_executable="$xcode_application/Contents/MacOS/Xcode"
  local xcodebuild_executable="$developer_directory/usr/bin/xcodebuild"
  [[ -d "$developer_directory" && ! -L "$developer_directory" ]] || \
    fail "proxy selected an invalid Xcode developer directory: $developer_directory"
  [[ -x "$xcode_executable" && ! -L "$xcode_executable" ]] || \
    fail "proxy selected an Xcode without an executable application: $xcode_executable"

  export XCBBUILDSERVICE_PATH="$proxy"
  export DEVELOPER_DIR="$developer_directory"
  export SWIFTBUILD_BAZEL_PROXY_MANIFEST="$manifest"
  export SWIFTBUILD_BAZEL_PROXY_MANIFEST_SHA256="$expected_manifest_sha256"
  export SWIFTBUILD_BAZEL_PROXY_PROJECT_IDENTITY="$project_identity"

  if [[ "$mode" == "xcode" ]]; then
    launch_xcode /usr/bin/open "$xcode_application" "$project" "$@"
    return
  fi

  [[ -x "$xcodebuild_executable" && ! -L "$xcodebuild_executable" ]] || \
    fail "proxy selected an Xcode without xcodebuild: $xcodebuild_executable"
  exec "$xcodebuild_executable" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
