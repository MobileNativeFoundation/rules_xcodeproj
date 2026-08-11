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
adapter_expansion_source="$(rlocation "$TEST_WORKSPACE/xcodeproj/internal/bazel_integration_files/actions.bzl")"
readonly adapter_expansion_source
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

# The installed adapter must contain the configured generator label, never its template token.
# Keep this guard next to the template assertion below so adding a placeholder requires wiring its
# Starlark expansion in the same review.
[[ "$(grep -Fc -- '"%generator_label%": str(generator_label)' "$adapter_expansion_source")" == 1 ]]

proxy_bep_block="$(sed -n '/SWIFTBUILD_BAZEL_PROXY_BEP_PATH:-/,/^fi$/p' "$adapter_source")"
readonly proxy_bep_block
[[ "$(grep -Fc -- '--build_event_publish_all_actions' <<< "$proxy_bep_block")" == 1 ]]
expected_bep_flag="--build_event_json_file=\$SWIFTBUILD_BAZEL_PROXY_BEP_PATH"
readonly expected_bep_flag
[[ "$(grep -Fc -- "$expected_bep_flag" <<< "$proxy_bep_block")" == 1 ]]
[[ "$(grep -Fc -- '--build_event_max_named_set_of_file_entries=256' <<< "$proxy_bep_block")" == 1 ]]
[[ "$(grep -Fc -- '--progress_report_interval=1' <<< "$proxy_bep_block")" == 1 ]]

# Live progress cadence is proxy-only and must not alter ordinary generated builds.
build_pre_config_flags=(--existing-build-flag)
unset SWIFTBUILD_BAZEL_PROXY_BEP_PATH
eval "$proxy_bep_block"
[[ "${#build_pre_config_flags[@]}" == 1 ]]
[[ "${build_pre_config_flags[0]}" == "--existing-build-flag" ]]

build_pre_config_flags=(--existing-build-flag)
SWIFTBUILD_BAZEL_PROXY_BEP_PATH="$test_root/build event.jsonl"
export SWIFTBUILD_BAZEL_PROXY_BEP_PATH
eval "$proxy_bep_block"
[[ "${#build_pre_config_flags[@]}" == 5 ]]
[[ "${build_pre_config_flags[1]}" == "--build_event_publish_all_actions" ]]
[[ "${build_pre_config_flags[2]}" == "--build_event_json_file=$SWIFTBUILD_BAZEL_PROXY_BEP_PATH" ]]
[[ "${build_pre_config_flags[3]}" == "--build_event_max_named_set_of_file_entries=256" ]]
[[ "${build_pre_config_flags[4]}" == "--progress_report_interval=1" ]]
unset SWIFTBUILD_BAZEL_PROXY_BEP_PATH

proxy_execution_log_flags_block="$(sed -n '/# The build service gives every operation/,/^fi$/p' "$adapter_source")"
readonly proxy_execution_log_flags_block
# These are literal source fragments whose dollar expressions must not expand in this test shell.
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '--execution_log_compact_file=$SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH' <<< "$proxy_execution_log_flags_block")" == 1 ]]
[[ "$(grep -Fc -- '"--execution_log_binary_file="' <<< "$proxy_execution_log_flags_block")" == 1 ]]
[[ "$(grep -Fc -- '"--execution_log_json_file="' <<< "$proxy_execution_log_flags_block")" == 1 ]]
[[ "$(grep -Fc -- '--noexecution_log_sort' <<< "$proxy_execution_log_flags_block")" == 0 ]]

# With no proxy path, the adapter must pass exactly the pre-existing build flags to Bazel.
build_pre_config_flags=(--existing-build-flag "--define=ordinary=value with spaces")
ordinary_build_flags_before="$(declare -p build_pre_config_flags)"
unset SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH
eval "$proxy_execution_log_flags_block"
[[ "$(declare -p build_pre_config_flags)" == "$ordinary_build_flags_before" ]]
[[ "${#build_pre_config_flags[@]}" == 2 ]]
[[ "${build_pre_config_flags[0]}" == "--existing-build-flag" ]]
[[ "${build_pre_config_flags[1]}" == "--define=ordinary=value with spaces" ]]

# With a proxy path, conflicting formats are cleared and the private compact path wins verbatim.
build_pre_config_flags=(--existing-build-flag)
readonly expected_execution_log_path="$test_root/execution log.compact"
SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH="$expected_execution_log_path"
export SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH
eval "$proxy_execution_log_flags_block"
[[ "${#build_pre_config_flags[@]}" == 4 ]]
[[ "${build_pre_config_flags[0]}" == "--existing-build-flag" ]]
[[ "${build_pre_config_flags[1]}" == "--execution_log_binary_file=" ]]
[[ "${build_pre_config_flags[2]}" == "--execution_log_compact_file=$expected_execution_log_path" ]]
[[ "${build_pre_config_flags[3]}" == "--execution_log_json_file=" ]]
unset SWIFTBUILD_BAZEL_PROXY_EXECUTION_LOG_PATH

# Execution-log paths and sorting are proxy-owned evidence plumbing, not invocation policy. Keep
# current and legacy metadata options out of the publishable invocation receipt.
proxy_receipt_command_options_block="$(sed -n '/for option in .*build_pre_config_flags/,/^  done$/p' "$bazel_build_source")"
readonly proxy_receipt_command_options_block
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --execution_log_compact_file=*' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --execution_log_json_file=*' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --execution_log_binary_file=*' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --noexecution_log_sort' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --build_event_max_named_set_of_file_entries=*' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --progress_report_interval=*' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --build_event_publish_all_actions' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --profile=*' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --generate_json_trace_profile=*' <<< "$proxy_receipt_command_options_block")" == 1 ]]
# The extracted source fragment consumes this array through `eval` below.
# shellcheck disable=SC2034
base_pre_config_flags=(--base-build-flag)
build_pre_config_flags=(
  "--execution_log_compact_file=$expected_execution_log_path"
  "--execution_log_json_file=$expected_execution_log_path"
  "--execution_log_binary_file=$expected_execution_log_path"
  --noexecution_log_sort
  --build_event_max_named_set_of_file_entries=256
  --progress_report_interval=1
  --build_event_publish_all_actions
  "--profile=$test_root/user-profile.json.gz"
  --generate_json_trace_profile=true
  --nogenerate_json_trace_profile
  --kept-build-flag
)
receipt_args=()
eval "$proxy_receipt_command_options_block"
[[ "${#receipt_args[@]}" == 2 ]]
[[ "${receipt_args[0]}" == "--command-option=--base-build-flag" ]]
[[ "${receipt_args[1]}" == "--command-option=--kept-build-flag" ]]

# The action-start signal is proxy-only, comes after the named config so it cannot be disabled by
# a bazelrc, and remains private orchestration rather than a semantic invocation-receipt option.
proxy_action_start_flags_block="$(sed -n '/SWIFTBUILD_BAZEL_PROXY_ACTION_STARTS_PATH:-/,/^fi$/p' "$bazel_build_source")"
readonly proxy_action_start_flags_block
[[ "$(grep -Fc -- 'build_log_cmd+=(--subcommands=pretty_print)' <<< "$proxy_action_start_flags_block")" == 1 ]]
[[ "$(grep -Fc -- 'receipt_args+=' <<< "$proxy_action_start_flags_block")" == 0 ]]

# The profile is proxy-owned, comes after the named config, and keeps the exact operation-scoped
# path out of the publishable invocation receipt.
proxy_profile_flags_block="$(sed -n '/^if \[\[ -n "${SWIFTBUILD_BAZEL_PROXY_PROFILE_PATH:-}" \]\]; then$/,/^fi$/p' "$bazel_build_source")"
readonly proxy_profile_flags_block
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '--profile=$SWIFTBUILD_BAZEL_PROXY_PROFILE_PATH' <<< "$proxy_profile_flags_block")" == 1 ]]
build_log_cmd=(--existing-build-flag)
unset SWIFTBUILD_BAZEL_PROXY_PROFILE_PATH
eval "$proxy_profile_flags_block"
[[ "${build_log_cmd[*]}" == "--existing-build-flag" ]]
readonly expected_profile_path="$test_root/bazel profile.json.gz"
build_log_cmd=(--existing-build-flag)
SWIFTBUILD_BAZEL_PROXY_PROFILE_PATH="$expected_profile_path"
export SWIFTBUILD_BAZEL_PROXY_PROFILE_PATH
eval "$proxy_profile_flags_block"
[[ "${build_log_cmd[0]}" == "--existing-build-flag" ]]
[[ "${build_log_cmd[1]}" == "--profile=$expected_profile_path" ]]

# The profile is secured for successful, failed, and interrupted builds. A missing profile is valid
# when Bazel terminates before creating it; a linked or non-regular result fails closed.
proxy_profile_permissions_block="$(sed -n '/^secure_build_proxy_profile() {$/,/^}$/p' "$bazel_build_source")"
readonly proxy_profile_permissions_block
eval "$proxy_profile_permissions_block"
printf 'private Bazel trace\n' > "$expected_profile_path"
chmod 666 "$expected_profile_path"
secure_build_proxy_profile
# shellcheck disable=SC2012
[[ "$(LC_ALL=C ls -l "$expected_profile_path" | cut -c 1-10)" == "-rw-------" ]]
rm "$expected_profile_path"
secure_build_proxy_profile
printf 'outside\n' > "$test_root/outside-profile"
ln -s "$test_root/outside-profile" "$expected_profile_path"
if secure_build_proxy_profile 2> /dev/null; then
  echo >&2 "Expected linked Bazel profile to fail closed"
  exit 1
fi
rm "$expected_profile_path"
unset SWIFTBUILD_BAZEL_PROXY_PROFILE_PATH

# A proxied adapter is already the inner Xcode invocation. Preserve the generated hermetic Bazel
# executable (or an explicitly inherited one), and tell workspace wrappers not to regenerate their
# outer rules release inside Xcode's restricted PATH.
proxy_bazel_environment_block="$(sed -n '/readonly build_proxy_bazel_real=/,/^fi$/p' "$bazel_build_source")"
readonly proxy_bazel_environment_block
readonly synthetic_integration="$test_root/synthetic-integration"
mkdir -p "$synthetic_integration"
cat > "$synthetic_integration/bazel_env.sh" <<'EOF'
envs=(LANG=C BAZEL_REAL=/generated/bazel)
EOF
BAZEL_INTEGRATION_DIR="$synthetic_integration"
SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR="$test_root/request"
(
  unset BAZEL_REAL
  eval "$proxy_bazel_environment_block"
  [[ "${envs[*]}" == "LANG=C BAZEL_REAL=/generated/bazel BUILD_WORKSPACE_DIRECTORY=$PWD" ]]
)
(
  BAZEL_REAL=/inherited/bazel
  eval "$proxy_bazel_environment_block"
  [[ "${envs[*]}" == "LANG=C BAZEL_REAL=/inherited/bazel BUILD_WORKSPACE_DIRECTORY=$PWD" ]]
)
(
  unset BAZEL_REAL SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR
  eval "$proxy_bazel_environment_block"
  [[ "${envs[*]}" == "LANG=C BAZEL_REAL=/generated/bazel" ]]
)
unset SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR

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
  'action_graph_query="deps(%generator_label%)"' \
  'action_graph_flags+=("--action_env=TOOLCHAINS=$toolchain")' \
  '"--config=$config"' \
  '"$output_groups_flag"' \
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
# The follow-up aquery must not re-resolve user labels in a potentially different top-level
# configuration from the generated output-group target that the successful build used.
# shellcheck disable=SC2016
[[ "$(grep -Fc -- 'action_graph_query="deps(${labels[0]})"' <<< "$proxy_action_graph_block")" == 0 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --build_event_json_file=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --build_event_max_named_set_of_file_entries=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --progress_report_interval=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --execution_log_compact_file=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --execution_log_json_file=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --execution_log_binary_file=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --noexecution_log_sort' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --profile=*' <<< "$proxy_action_graph_block")" == 1 ]]
# shellcheck disable=SC2016
[[ "$(grep -Fc -- '"$option" != --generate_json_trace_profile=*' <<< "$proxy_action_graph_block")" == 1 ]]
# The metadata-only aquery comes after the build and must not inherit command-printing from a
# common/build/config bazelrc or duplicate action-start events.
[[ "$(grep -Fxc -- '    --subcommands=false \' <<< "$proxy_action_graph_block")" == 1 ]]
[[ "$(grep -Fxc -- '    --profile= \' <<< "$proxy_action_graph_block")" == 1 ]]
[[ "$(grep -Fxc -- '    --generate_json_trace_profile=false \' <<< "$proxy_action_graph_block")" == 1 ]]
# Command-line clears come after the named config, so execution-log settings inherited directly
# from common/build/config bazelrc sections cannot leak into the metadata-only aquery.
for cleared_execution_log_flag in \
  '--execution_log_binary_file=' \
  '--execution_log_compact_file=' \
  '--execution_log_json_file='; do
  expected_clear_line="    $cleared_execution_log_flag \\"
  [[ "$(grep -Fxc -- "$expected_clear_line" <<< "$proxy_action_graph_block")" == 1 ]]
done
# shellcheck disable=SC2016
[[ "$(grep -Fc -- 'chmod 600 "$SWIFTBUILD_BAZEL_PROXY_ACTION_GRAPH_PATH"' <<< "$proxy_action_graph_block")" == 1 ]]

proxy_action_graph_filter_block="$(sed -n '/  action_graph_pre_config_flags=()/,/^  done$/p' "$adapter_source")"
readonly proxy_action_graph_filter_block
base_pre_config_flags=(
  "--execution_log_compact_file=$expected_execution_log_path"
  "--execution_log_json_file=$expected_execution_log_path"
  "--execution_log_binary_file=$expected_execution_log_path"
  --noexecution_log_sort
  --progress_report_interval=1
  "--profile=$test_root/user-profile.json.gz"
  --generate_json_trace_profile=true
  --nogenerate_json_trace_profile
  --kept-base-action-graph-flag
)
build_pre_config_flags=(
  "--execution_log_compact_file=$expected_execution_log_path"
  "--execution_log_json_file=$expected_execution_log_path"
  "--execution_log_binary_file=$expected_execution_log_path"
  --noexecution_log_sort
  --progress_report_interval=1
  "--profile=$test_root/user-profile.json.gz"
  --generate_json_trace_profile=false
  --kept-action-graph-flag
)
eval "$proxy_action_graph_filter_block"
[[ "${#action_graph_pre_config_flags[@]}" == 2 ]]
[[ "${action_graph_pre_config_flags[0]}" == "--kept-base-action-graph-flag" ]]
[[ "${action_graph_pre_config_flags[1]}" == "--kept-action-graph-flag" ]]

proxy_action_graph_flags_block="$(sed -n '/  action_graph_flags=(/,/^  readonly action_graph_flags$/p' "$adapter_source")"
readonly proxy_action_graph_flags_block
(
  set -u
  action_graph_pre_config_flags=(--base-flag)
  toolchain=
  eval "$proxy_action_graph_flags_block"
  [[ "${action_graph_flags[*]}" == "--base-flag" ]]
)
(
  set -u
  action_graph_pre_config_flags=(--base-flag --configured-flag)
  toolchain=com.example.toolchain
  eval "$proxy_action_graph_flags_block"
  [[ "${action_graph_flags[*]}" == "--base-flag --configured-flag --action_env=TOOLCHAINS=com.example.toolchain" ]]
)

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
