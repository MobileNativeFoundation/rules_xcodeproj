#!/bin/bash

set -euo pipefail

fail() {
  echo >&2 "rules_xcodeproj build proxy: ${1}"
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

destination=""
launcher=""
proxy=""
proxy_label=""
project_identity=""
proxy_sha256=""

while (("$#")); do
  case "$1" in
    --destination)
      destination="$2"
      shift 2
      ;;
    --launcher)
      launcher="$2"
      shift 2
      ;;
    --proxy)
      proxy="$2"
      shift 2
      ;;
    --proxy-label)
      proxy_label="$2"
      shift 2
      ;;
    --project-identity)
      project_identity="$2"
      shift 2
      ;;
    --proxy-sha256)
      proxy_sha256="$2"
      shift 2
      ;;
    *)
      fail "unrecognized argument: $1"
      ;;
  esac
done

[[ -n "$destination" ]] || fail "missing required argument: --destination"
[[ -d "$destination" ]] || fail "project destination is missing: $destination"

readonly proxy_directory="$destination/rules_xcodeproj/build_proxy"

# An absent configuration is the native-build-service default. Also remove a
# stale installation when a project changes from configured to unconfigured.
if [[ -z "$proxy" && -z "$launcher" && -z "$proxy_label" && \
      -z "$project_identity" && -z "$proxy_sha256" ]]
then
  rm -rf "$proxy_directory"
  exit 0
fi

[[ -n "$proxy" ]] || fail "missing required argument: --proxy"
[[ -n "$launcher" ]] || fail "missing required argument: --launcher"
[[ -n "$proxy_label" ]] || fail "missing required argument: --proxy-label"
[[ -n "$project_identity" ]] || fail "missing required argument: --project-identity"
[[ "$proxy_sha256" =~ ^[0-9a-f]{64}$ ]] || \
  fail "--proxy-sha256 must be a lowercase 64-character SHA-256 digest"

# Bazel runfiles are commonly symbolic links. Inputs may therefore be linked,
# but only their verified bytes are copied into the non-symbolic installation.
[[ -f "$proxy" && -x "$proxy" ]] || \
  fail "proxy is missing or not executable: $proxy"
[[ -f "$launcher" ]] || fail "launcher is missing: $launcher"

readonly manifest="$destination/rules_xcodeproj/bazel/build_proxy_manifest.json"
[[ -f "$manifest" && ! -L "$manifest" ]] || \
  fail "schema-v2 build-proxy manifest is missing or symbolic: $manifest"

actual_proxy_sha256="$(sha256_file "$proxy")"
readonly actual_proxy_sha256
[[ "$actual_proxy_sha256" == "$proxy_sha256" ]] || \
  fail "proxy SHA-256 mismatch: expected $proxy_sha256, got $actual_proxy_sha256"

manifest_sha256="$(sha256_file "$manifest")"
readonly manifest_sha256
readonly rules_directory="$destination/rules_xcodeproj"
build_proxy_staging="$(mktemp -d "$rules_directory/.build_proxy.XXXXXX")"
build_proxy_backup=""
published=0

cleanup() {
  if [[ $published -eq 0 && -n "${build_proxy_backup:-}" && \
        -d "$build_proxy_backup" && ! -e "$proxy_directory" ]]
  then
    if mv "$build_proxy_backup" "$proxy_directory"; then
      build_proxy_backup=""
    else
      echo >&2 \
        "rules_xcodeproj build proxy: rollback failed; prior installation remains at $build_proxy_backup"
    fi
  fi
  if [[ -n "${build_proxy_staging:-}" && -d "$build_proxy_staging" ]]; then
    rm -rf "$build_proxy_staging"
  fi
  if [[ -n "${build_proxy_backup:-}" && -d "$build_proxy_backup" && \
        -e "$proxy_directory" ]]
  then
    rm -rf "$build_proxy_backup"
  fi
}
trap cleanup EXIT

cp "$proxy" "$build_proxy_staging/build_service_proxy"
cp "$launcher" "$build_proxy_staging/launch_with_build_proxy.sh"
printf '%s\n' "$proxy_sha256" > "$build_proxy_staging/build_service_proxy.sha256"
printf '%s\n' "$manifest_sha256" > "$build_proxy_staging/build_proxy_manifest.sha256"
printf '%s\n' "$proxy_label" > "$build_proxy_staging/build_service_proxy.label"
printf '%s\n' "$project_identity" > "$build_proxy_staging/project_identity"

copied_proxy_sha256="$(sha256_file "$build_proxy_staging/build_service_proxy")"
readonly copied_proxy_sha256
[[ "$copied_proxy_sha256" == "$proxy_sha256" ]] || \
  fail "installed proxy SHA-256 mismatch: expected $proxy_sha256, got $copied_proxy_sha256"

chmod 0555 \
  "$build_proxy_staging/build_service_proxy" \
  "$build_proxy_staging/launch_with_build_proxy.sh"
chmod 0444 \
  "$build_proxy_staging/build_service_proxy.sha256" \
  "$build_proxy_staging/build_proxy_manifest.sha256" \
  "$build_proxy_staging/build_service_proxy.label" \
  "$build_proxy_staging/project_identity"

if [[ -e "$proxy_directory" ]]; then
  build_proxy_backup="$(mktemp -d "$rules_directory/.build_proxy.backup.XXXXXX")"
  rmdir "$build_proxy_backup"
  mv "$proxy_directory" "$build_proxy_backup"
fi
if ! mv "$build_proxy_staging" "$proxy_directory"; then
  fail "failed to publish the verified build-proxy installation"
fi
build_proxy_staging=""
published=1
if [[ -n "$build_proxy_backup" ]]; then
  rm -rf "$build_proxy_backup"
  build_proxy_backup=""
fi
