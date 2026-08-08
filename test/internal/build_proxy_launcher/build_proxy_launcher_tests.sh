#!/bin/bash

set -euo pipefail

# --- begin runfiles.bash initialization ---
if [[ ! -d "${RUNFILES_DIR:-/dev/null}" && ! -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  if [[ -f "$0.runfiles_manifest" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
  elif [[ -f "$0.runfiles/MANIFEST" ]]; then
    export RUNFILES_MANIFEST_FILE="$0.runfiles/MANIFEST"
  elif [[ -f "$0.runfiles/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
    export RUNFILES_DIR="$0.runfiles"
  fi
fi
if [[ -f "${RUNFILES_DIR:-/dev/null}/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
  # shellcheck source=/dev/null
  source "${RUNFILES_DIR}/bazel_tools/tools/bash/runfiles/runfiles.bash"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  # shellcheck source=/dev/null
  source "$(grep -m1 "^bazel_tools/tools/bash/runfiles/runfiles.bash " \
    "$RUNFILES_MANIFEST_FILE" | cut -d ' ' -f 2-)"
else
  echo >&2 "ERROR: cannot find @bazel_tools//tools/bash/runfiles:runfiles.bash"
  exit 1
fi
# --- end runfiles.bash initialization ---

installer="$(rlocation "$TEST_WORKSPACE/xcodeproj/internal/templates/install_build_proxy.sh")"
readonly installer
launcher_source="$(rlocation "$TEST_WORKSPACE/xcodeproj/internal/templates/build_proxy_launcher.sh")"
readonly launcher_source
adapter_source="$(rlocation "$TEST_WORKSPACE/xcodeproj/internal/templates/generate_bazel_dependencies.sh")"
readonly adapter_source
bazel_build_source="$(rlocation "$TEST_WORKSPACE/xcodeproj/internal/templates/bazel_build.sh")"
readonly bazel_build_source
configured_runner="$(rlocation "$TEST_WORKSPACE/test/internal/build_proxy_launcher/configured_runner-runner.sh")"
readonly configured_runner
test_root="$(mktemp -d "$TEST_TMPDIR/build-proxy-launcher.XXXXXX")"
readonly test_root
readonly project="$test_root/App.xcodeproj"
readonly manifest="$project/rules_xcodeproj/bazel/build_proxy_manifest.json"
readonly source_proxy="$test_root/source-proxy"
readonly xcode_application="$test_root/Xcode-Exact.app"
readonly native_service="$xcode_application/Contents/SharedFrameworks/SwiftBuild.framework/Versions/A/PlugIns/SWBBuildService.bundle/Contents/MacOS/SWBBuildService"
readonly xcode_executable="$xcode_application/Contents/MacOS/Xcode"
readonly xcodebuild_executable="$xcode_application/Contents/Developer/usr/bin/xcodebuild"
readonly capture="$test_root/capture"

project_identity_flag="$(grep -F -- '--build_proxy_project_identity ' "$configured_runner")"
readonly project_identity_flag
[[ "$project_identity_flag" == *'//generator/test/internal/build_proxy_launcher/configured_runner:configured_runner' ]]

proxy_bep_block="$(sed -n '/SWIFTBUILD_BAZEL_PROXY_BEP_PATH:-/,/^fi$/p' "$adapter_source")"
readonly proxy_bep_block
[[ "$(grep -Fc -- '--build_event_publish_all_actions' <<< "$proxy_bep_block")" == 1 ]]
expected_bep_flag="--build_event_json_file=\$SWIFTBUILD_BAZEL_PROXY_BEP_PATH"
readonly expected_bep_flag
[[ "$(grep -Fc -- "$expected_bep_flag" <<< "$proxy_bep_block")" == 1 ]]

proxy_execution_log_flags_block="$(sed -n '/# The build service gives every operation/,/^fi$/p' "$adapter_source")"
readonly proxy_execution_log_flags_block
# These are literal source fragments whose dollar expressions must not expand in this test shell.
# shellcheck disable=SC2016
for expected_execution_log_flag in \
  '--execution_log_json_file=$SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH' \
  '--noexecution_log_sort'; do
  [[ "$(grep -Fc -- "$expected_execution_log_flag" <<< "$proxy_execution_log_flags_block")" == 1 ]]
done

# With no proxy path, the adapter must pass exactly the pre-existing build flags to Bazel.
build_pre_config_flags=(--existing-build-flag)
unset SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH
eval "$proxy_execution_log_flags_block"
[[ "${build_pre_config_flags[*]}" == "--existing-build-flag" ]]

# With a proxy path, the two execution-log flags are appended to the actual build flags verbatim.
readonly expected_execution_log_path="$test_root/execution log.jsonl"
SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH="$expected_execution_log_path"
export SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH
eval "$proxy_execution_log_flags_block"
[[ "${#build_pre_config_flags[@]}" == 3 ]]
[[ "${build_pre_config_flags[0]}" == "--existing-build-flag" ]]
[[ "${build_pre_config_flags[1]}" == "--execution_log_json_file=$expected_execution_log_path" ]]
[[ "${build_pre_config_flags[2]}" == "--noexecution_log_sort" ]]
unset SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH

# Execution-log paths and sorting are proxy-owned evidence plumbing, not invocation policy. Keep
# the volatile absolute path and its companion option out of the publishable invocation receipt.
proxy_receipt_command_options_block="$(sed -n '/for option in .*build_pre_config_flags/,/^  done$/p' "$bazel_build_source")"
readonly proxy_receipt_command_options_block
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --execution_log_json_file=*' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --noexecution_log_sort' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# The extracted source fragment consumes this array through `eval` below.
# shellcheck disable=SC2034
base_pre_config_flags=(--base-build-flag)
build_pre_config_flags=(
  "--execution_log_json_file=$expected_execution_log_path"
  --noexecution_log_sort
  --kept-build-flag
)
receipt_args=()
eval "$proxy_receipt_command_options_block"
[[ "${#receipt_args[@]}" == 2 ]]
[[ "${receipt_args[0]}" == "--command-option=--base-build-flag" ]]
[[ "${receipt_args[1]}" == "--command-option=--kept-build-flag" ]]

# The build must finish before the adapter makes the exact expected execution-log path private.
proxy_execution_log_permissions_block="$(sed -n '/# Bazel has successfully returned/,/^fi$/p' "$adapter_source")"
readonly proxy_execution_log_permissions_block
# shellcheck disable=SC2016
[[ "$(grep -Fc -- 'chmod 600 "$SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH"' <<< "$proxy_execution_log_permissions_block")" == 1 ]]
SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH="$expected_execution_log_path"
export SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH
printf 'private command metadata\n' > "$expected_execution_log_path"
chmod 666 "$expected_execution_log_path"
eval "$proxy_execution_log_permissions_block"
# This is a generated private file with a controlled name; the permission string is portable.
# shellcheck disable=SC2012
[[ "$(LC_ALL=C ls -l "$expected_execution_log_path" | cut -c 1-10)" == "-rw-------" ]]
rm "$expected_execution_log_path"
if (eval "$proxy_execution_log_permissions_block") 2> /dev/null; then
  echo >&2 "Expected missing execution log to fail closed"
  exit 1
fi
unset SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH

proxy_action_graph_block="$(sed -n '/SWIFTBUILD_BAZEL_PROXY_ACTION_GRAPH_PATH:-/,/^fi$/p' "$adapter_source")"
readonly proxy_action_graph_block
# These are literal source fragments whose dollar expressions must not expand in this test shell.
# shellcheck disable=SC2016
for expected_action_graph_flag in \
  'aquery' \
  'action_graph_query="deps(${labels[0]})"' \
  'action_graph_query="deps(set(${labels[*]}))"' \
  'action_graph_toolchain_flags+=("--action_env=TOOLCHAINS=$toolchain")' \
  '"--config=$config"' \
  '--color=no' \
  '--output=jsonproto' \
  '--include_commandline' \
  '--noinclude_param_files' \
  '--noinclude_file_write_contents' \
  '--include_artifacts' \
  '--consistent_labels' \
  '--output_file=$SWIFTBUILD_BAZEL_PROXY_ACTION_GRAPH_PATH'; do
  [[ "$(grep -Fc -- "$expected_action_graph_flag" <<< "$proxy_action_graph_block")" == 1 ]]
done
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --build_event_json_file=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --execution_log_json_file=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --noexecution_log_sort' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- 'chmod 600 "$SWIFTBUILD_BAZEL_PROXY_ACTION_GRAPH_PATH"' <<< "$proxy_action_graph_block")" == 1 ]]

sha256_file() {
  if command -v sha256sum > /dev/null 2>&1; then
    sha256sum -- "$1" | awk '{print $1}'
  else
    shasum -a 256 -- "$1" | awk '{print $1}'
  fi
}

assert_fails() {
  local description="$1"
  shift
  if "$@" > "$test_root/failure.stdout" 2> "$test_root/failure.stderr"; then
    echo >&2 "Expected failure: $description"
    exit 1
  fi
}

write_manifest() {
  printf '%s\n' '{"capabilities":{"actions":["build","clean","indexbuild","preview"]},"ignoredXcodeTargetGUIDs":[],"invocation":{"adapterPath":"rules_xcodeproj/bazel/generate_bazel_dependencies.sh","bazelPath":"/usr/bin/false","bazelrcPath":"rules_xcodeproj/bazel/xcodeproj.bazelrc","environmentKeys":[],"generatorLabel":"@@rules_xcodeproj_generated//generator/app/project","receiptSchemaVersion":1},"project":{"containerName":"App.xcodeproj","identity":"@@rules_xcodeproj_generated//generator/app/project"},"schemaVersion":2,"targets":[]}' > "$manifest"
}

mkdir -p \
  "$(dirname "$manifest")" \
  "$(dirname "$native_service")" \
  "$(dirname "$xcode_executable")" \
  "$(dirname "$xcodebuild_executable")"
write_manifest

printf '%s\n' '#!/bin/bash' 'exit 0' > "$native_service"
printf '%s\n' '#!/bin/bash' 'exit 0' > "$xcode_executable"
cat > "$source_proxy" <<'EOF'
#!/bin/bash
if [[ "${1:-}" == "--resolve-native-service" && $# == 1 ]]; then
  if [[ "${FAKE_PROXY_STATUS:-0}" != 0 ]]; then
    exit "$FAKE_PROXY_STATUS"
  fi
  printf '%s\n' "$FAKE_NATIVE_SERVICE"
  exit 0
fi
exit 78
EOF
cat > "$xcodebuild_executable" <<'EOF'
#!/bin/bash
{
  printf 'proxy=%s\n' "$XCBBUILDSERVICE_PATH"
  printf 'developer=%s\n' "$DEVELOPER_DIR"
  printf 'manifest=%s\n' "$SWIFTBUILD_BAZEL_PROXY_MANIFEST"
  printf 'manifest_sha256=%s\n' "$SWIFTBUILD_BAZEL_PROXY_MANIFEST_SHA256"
  printf 'identity=%s\n' "$SWIFTBUILD_BAZEL_PROXY_PROJECT_IDENTITY"
  printf 'args=%s\n' "$*"
} > "$FAKE_CAPTURE"
EOF
chmod +x "$source_proxy" "$native_service" "$xcode_executable" "$xcodebuild_executable"

proxy_sha256="$(sha256_file "$source_proxy")"
readonly proxy_sha256
readonly project_identity="@@rules_xcodeproj_generated//generator/app/project"

"$installer" \
  --destination "$project" \
  --launcher "$launcher_source" \
  --project-identity "$project_identity" \
  --proxy "$source_proxy" \
  --proxy-label "//tools:standalone_build_proxy" \
  --proxy-sha256 "$proxy_sha256"

readonly installed_directory="$project/rules_xcodeproj/build_proxy"
readonly installed_launcher="$installed_directory/launch_with_build_proxy.sh"
readonly installed_proxy="$installed_directory/build_service_proxy"
[[ -x "$installed_launcher" ]]
[[ -x "$installed_proxy" ]]
[[ "$(<"$installed_directory/build_service_proxy.sha256")" == "$proxy_sha256" ]]
[[ "$(<"$installed_directory/build_proxy_manifest.sha256")" == "$(sha256_file "$manifest")" ]]
[[ "$(<"$installed_directory/build_service_proxy.label")" == "//tools:standalone_build_proxy" ]]
[[ "$(<"$installed_directory/project_identity")" == "$project_identity" ]]

FAKE_NATIVE_SERVICE="$native_service" FAKE_CAPTURE="$capture" \
  "$installed_launcher" xcodebuild -project "$project" build
grep -Fx "proxy=$installed_proxy" "$capture"
grep -Fx "developer=$xcode_application/Contents/Developer" "$capture"
grep -Fx "manifest=$manifest" "$capture"
grep -Fx "manifest_sha256=$(sha256_file "$manifest")" "$capture"
grep -Fx "identity=$project_identity" "$capture"
grep -Fx "args=-project $project build" "$capture"

assert_fails "unsupported launcher mode" \
  env FAKE_NATIVE_SERVICE="$native_service" "$installed_launcher" arbitrary-command
grep -F "expected xcode or xcodebuild" "$test_root/failure.stderr"

FAKE_PROXY_STATUS=78 assert_fails "proxy compatibility preflight" \
  env FAKE_NATIVE_SERVICE="$native_service" FAKE_PROXY_STATUS=78 \
  "$installed_launcher" xcodebuild -version
grep -F "compatibility check failed" "$test_root/failure.stderr"

chmod u+w "$installed_proxy"
printf '\n# tampered\n' >> "$installed_proxy"
assert_fails "runtime proxy digest mismatch" \
  env FAKE_NATIVE_SERVICE="$native_service" "$installed_launcher" xcodebuild -version
grep -F "proxy SHA-256 mismatch" "$test_root/failure.stderr"

assert_fails "generation-time proxy digest mismatch" \
  "$installer" \
  --destination "$project" \
  --launcher "$launcher_source" \
  --project-identity "$project_identity" \
  --proxy "$source_proxy" \
  --proxy-label "//tools:standalone_build_proxy" \
  --proxy-sha256 "0000000000000000000000000000000000000000000000000000000000000000"
grep -F "proxy SHA-256 mismatch" "$test_root/failure.stderr"
grep -F "# tampered" "$installed_proxy"

"$installer" \
  --destination "$project" \
  --launcher "$launcher_source" \
  --project-identity "$project_identity" \
  --proxy "$source_proxy" \
  --proxy-label "//tools:standalone_build_proxy" \
  --proxy-sha256 "$proxy_sha256"
printf '\n' >> "$manifest"
assert_fails "runtime manifest digest mismatch" \
  env FAKE_NATIVE_SERVICE="$native_service" "$installed_launcher" xcodebuild -version
grep -F "manifest SHA-256 mismatch" "$test_root/failure.stderr"
write_manifest

readonly replacement_proxy="$test_root/replacement-proxy"
cp "$source_proxy" "$replacement_proxy"
printf '\n# replacement\n' >> "$replacement_proxy"
chmod +x "$replacement_proxy"
replacement_sha256="$(sha256_file "$replacement_proxy")"
readonly replacement_sha256
readonly rollback_tools="$test_root/rollback-tools"
readonly rollback_count="$test_root/rollback-count"
mkdir "$rollback_tools"
printf '0\n' > "$rollback_count"
cat > "$rollback_tools/mv" <<'EOF'
#!/bin/bash
count="$(<"$FAKE_MV_COUNT")"
count=$((count + 1))
printf '%s\n' "$count" > "$FAKE_MV_COUNT"
if [[ $count -eq 2 ]]; then
  exit 9
fi
exec /bin/mv "$@"
EOF
chmod +x "$rollback_tools/mv"
assert_fails "publication rollback" \
  env PATH="$rollback_tools:/usr/bin:/bin" FAKE_MV_COUNT="$rollback_count" \
  "$installer" \
  --destination "$project" \
  --launcher "$launcher_source" \
  --project-identity "$project_identity" \
  --proxy "$replacement_proxy" \
  --proxy-label "//tools:replacement_build_proxy" \
  --proxy-sha256 "$replacement_sha256"
grep -F "failed to publish" "$test_root/failure.stderr"
[[ "$(sha256_file "$installed_proxy")" == "$proxy_sha256" ]]
[[ "$(<"$installed_directory/build_service_proxy.label")" == "//tools:standalone_build_proxy" ]]
[[ "$(<"$rollback_count")" == 3 ]]

readonly malformed_tools="$test_root/malformed-tools"
mkdir "$malformed_tools"
cat > "$malformed_tools/sha256sum" <<'EOF'
#!/bin/bash
echo malformed
EOF
chmod +x "$malformed_tools/sha256sum"
assert_fails "malformed SHA-256 tool output" \
  env PATH="$malformed_tools:/usr/bin:/bin" "$installer" \
  --destination "$project" \
  --launcher "$launcher_source" \
  --project-identity "$project_identity" \
  --proxy "$source_proxy" \
  --proxy-label "//tools:standalone_build_proxy" \
  --proxy-sha256 "$proxy_sha256"
grep -F "malformed output" "$test_root/failure.stderr"

readonly failing_tools="$test_root/failing-tools"
mkdir "$failing_tools"
cat > "$failing_tools/sha256sum" <<'EOF'
#!/bin/bash
exit 3
EOF
chmod +x "$failing_tools/sha256sum"
assert_fails "failing SHA-256 tool" \
  env PATH="$failing_tools:/usr/bin:/bin" "$installer" \
  --destination "$project" \
  --launcher "$launcher_source" \
  --project-identity "$project_identity" \
  --proxy "$source_proxy" \
  --proxy-label "//tools:standalone_build_proxy" \
  --proxy-sha256 "$proxy_sha256"
grep -F "calculation failed" "$test_root/failure.stderr"

readonly no_tools="$test_root/no-tools"
mkdir "$no_tools"
assert_fails "missing SHA-256 tool" \
  env PATH="$no_tools" /bin/bash "$installer" \
  --destination "$project" \
  --launcher "$launcher_source" \
  --project-identity "$project_identity" \
  --proxy "$source_proxy" \
  --proxy-label "//tools:standalone_build_proxy" \
  --proxy-sha256 "$proxy_sha256"
grep -F "neither sha256sum nor shasum" "$test_root/failure.stderr"

# shellcheck source=/dev/null
source "$launcher_source"
readonly fake_open="$test_root/open"
readonly open_capture="$test_root/open-capture"
cat > "$fake_open" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$FAKE_OPEN_CAPTURE"
EOF
chmod +x "$fake_open"
export XCBBUILDSERVICE_PATH="$installed_proxy"
export DEVELOPER_DIR="$xcode_application/Contents/Developer"
export SWIFTBUILD_BAZEL_PROXY_MANIFEST="$manifest"
SWIFTBUILD_BAZEL_PROXY_MANIFEST_SHA256="$(sha256_file "$manifest")"
export SWIFTBUILD_BAZEL_PROXY_MANIFEST_SHA256
export SWIFTBUILD_BAZEL_PROXY_PROJECT_IDENTITY="$project_identity"
FAKE_OPEN_CAPTURE="$open_capture" launch_xcode \
  "$fake_open" "$xcode_application" "$project"
grep -Fx -- "-n" "$open_capture"
grep -Fx -- "-F" "$open_capture"
grep -Fx -- "XCBBUILDSERVICE_PATH=$installed_proxy" "$open_capture"
grep -Fx -- "SWIFTBUILD_BAZEL_PROXY_MANIFEST=$manifest" "$open_capture"
grep -Fx -- "$project" "$open_capture"

"$installer" --destination "$project"
[[ ! -e "$installed_directory" ]]
