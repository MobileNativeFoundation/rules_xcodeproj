#!/bin/bash

set -euo pipefail

fail() {
  echo >&2 "FAIL: $*"
  exit 1
}

assert_status() {
  local expected="$1"
  local actual="$2"
  local description="$3"
  [[ "$actual" == "$expected" ]] || \
    fail "$description: expected status $expected, got $actual"
}

require_absent() {
  local path="$1"
  [[ ! -e "$path" && ! -L "$path" ]] || fail "unexpected output: $path"
}

readonly repo_root="$TEST_SRCDIR/$TEST_WORKSPACE"
readonly facade="$repo_root/xcodeproj/internal/bazel_integration_files/clang"
readonly cxx_facade="$repo_root/xcodeproj/internal/bazel_integration_files/clang++"
readonly sibling_ld="$repo_root/xcodeproj/internal/bazel_integration_files/ld"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/clang-facade-tests.XXXXXX")"
readonly test_root
trap 'rm -rf "$test_root"' EXIT

[[ "${facade##*/}" == "clang" ]] || fail "facade basename is not clang"
[[ -x "$facade" ]] || fail "packaged facade is not executable"
/bin/bash -n "$facade"
[[ -x "$cxx_facade" ]] || fail "packaged C++ facade is not executable"
/bin/bash -n "$cxx_facade"

readonly developer_dir="$test_root/Xcode With Spaces.app/Contents/Developer"
readonly sdk="$developer_dir/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
readonly real_clang="$developer_dir/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
readonly execroot_requested="$test_root/build output base/execroot/_main"
readonly record_dir="$test_root/records"
mkdir -p "${real_clang%/*}" "$sdk" "$execroot_requested" "$record_dir"
execroot="$(cd "$execroot_requested" && /bin/pwd -P)"
readonly execroot

cat > "$real_clang" <<'EOF'
#!/bin/bash
set -euo pipefail
printf '%s\0' "$@" > "$RECORD_DIR/$RECORD_NAME.argv.nul"
printf 'fake-clang-stdout\n'
printf 'fake-clang-stderr\n' >&2
exit 73
EOF
chmod 0755 "$real_clang"

readonly valid_response="$test_root/valid response.params"
cat > "$valid_response" <<'EOF'
-Xlinker
-objc_abi_version
-Xlinker
2
-framework
SwiftUI
-Xlinker
-install_name
-Xlinker
@rpath/PreviewHost.debug.dylib
EOF

run_capture() {
  local name="$1"
  shift
  set +e
  RECORD_DIR="$record_dir" RECORD_NAME="$name" \
    "$@" > "$test_root/$name.stdout" 2> "$test_root/$name.stderr"
  local status=$?
  set -e
  printf '%s\n' "$status" > "$test_root/$name.status"
}

# Ordinary calls must remain byte-for-byte behaviorally identical to the
# existing sibling `ld`, including the no-sysroot dependency-info path.
readonly direct_dependency_info="$test_root/direct_dependency_info.dat"
readonly facade_dependency_info="$test_root/facade_dependency_info.dat"
readonly ordinary_output="$test_root/ordinary.framework/ordinary"
run_capture ordinary-direct \
  "$sibling_ld" \
  -o "$ordinary_output" \
  -Xlinker -dependency_info -Xlinker "$direct_dependency_info"
run_capture ordinary-facade \
  "$facade" \
  -o "$ordinary_output" \
  -Xlinker -dependency_info -Xlinker "$facade_dependency_info"
assert_status 0 "$(<"$test_root/ordinary-direct.status")" "direct ordinary route"
assert_status 0 "$(<"$test_root/ordinary-facade.status")" "facade ordinary route"
cmp "$test_root/ordinary-direct.stdout" "$test_root/ordinary-facade.stdout"
cmp "$test_root/ordinary-direct.stderr" "$test_root/ordinary-facade.stderr"
cmp "$direct_dependency_info" "$facade_dependency_info"
require_absent "$ordinary_output"

readonly cxx_dependency_info="$test_root/cxx_dependency_info.dat"
run_capture ordinary-cxx-facade \
  "$cxx_facade" \
  -o "$ordinary_output" \
  -Xlinker -dependency_info -Xlinker "$cxx_dependency_info"
assert_status 0 "$(<"$test_root/ordinary-cxx-facade.status")" \
  "C++ facade ordinary route"
cmp "$test_root/ordinary-direct.stdout" "$test_root/ordinary-cxx-facade.stdout"
cmp "$test_root/ordinary-direct.stderr" "$test_root/ordinary-cxx-facade.stderr"
cmp "$direct_dependency_info" "$cxx_dependency_info"
require_absent "$ordinary_output"

readonly query_output="$test_root/query.framework/query"
readonly -a query_args=(
  -target arm64-apple-ios15.0-simulator
  -isysroot "$sdk"
  -working-directory "$execroot"
  "@$valid_response"
  -o "$query_output"
  -###
)
run_capture query "$facade" "${query_args[@]}"
if [[ "$(<"$test_root/query.status")" != 73 ]]; then
  cat "$test_root/query.stderr" >&2
fi
assert_status 73 "$(<"$test_root/query.status")" "query route"
printf '%s\0' "${query_args[@]}" > "$test_root/query.expected.nul"
cmp "$test_root/query.expected.nul" "$record_dir/query.argv.nul"
[[ "$(<"$test_root/query.stdout")" == "fake-clang-stdout" ]]
[[ "$(<"$test_root/query.stderr")" == "fake-clang-stderr" ]]
require_absent "$query_output"

run_capture cxx-query "$cxx_facade" "${query_args[@]}"
assert_status 73 "$(<"$test_root/cxx-query.status")" "C++ query route"
printf '%s\0' --driver-mode=g++ "${query_args[@]}" > \
  "$test_root/cxx-query.expected.nul"
cmp "$test_root/cxx-query.expected.nul" "$record_dir/cxx-query.argv.nul"
require_absent "$query_output"

# Xcode runs this `-###` probe to discover the profile and Apple runtime
# libraries that it must add to a libtool invocation. Clang supplies its
# implicit `a.out` output, so the query intentionally has no `-o` or
# `-working-directory` argument.
readonly -a profile_runtime_query_args=(
  -Xlinker -reproducible
  -isysroot "$sdk"
  -fprofile-instr-generate
  -fapple-link-rtlib
  -###
)
run_capture profile-runtime-query \
  "$facade" "${profile_runtime_query_args[@]}"
assert_status 73 "$(<"$test_root/profile-runtime-query.status")" \
  "profile runtime query route"
printf '%s\0' "${profile_runtime_query_args[@]}" > \
  "$test_root/profile-runtime-query.expected.nul"
cmp \
  "$test_root/profile-runtime-query.expected.nul" \
  "$record_dir/profile-runtime-query.argv.nul"
[[ "$(<"$test_root/profile-runtime-query.stdout")" == "fake-clang-stdout" ]]
[[ "$(<"$test_root/profile-runtime-query.stderr")" == "fake-clang-stderr" ]]

run_capture cxx-profile-runtime-query \
  "$cxx_facade" "${profile_runtime_query_args[@]}"
assert_status 73 "$(<"$test_root/cxx-profile-runtime-query.status")" \
  "C++ profile runtime query route"
printf '%s\0' --driver-mode=g++ "${profile_runtime_query_args[@]}" > \
  "$test_root/cxx-profile-runtime-query.expected.nul"
cmp \
  "$test_root/cxx-profile-runtime-query.expected.nul" \
  "$record_dir/cxx-profile-runtime-query.argv.nul"

if [[ "$execroot" == /private/* ]]; then
  alias_execroot="${execroot#/private}"
else
  alias_execroot="/private$execroot"
fi
if [[ -d "$alias_execroot" ]]; then
  alias_query_args=(
    -target arm64-apple-ios15.0-simulator
    -isysroot "$sdk"
    -working-directory "$alias_execroot"
    "@$valid_response"
    -o "$query_output"
    -###
  )
  run_capture query-private-alias "$facade" "${alias_query_args[@]}"
  assert_status 73 "$(<"$test_root/query-private-alias.status")" \
    "query /private alias route"
  printf '%s\0' "${alias_query_args[@]}" > \
    "$test_root/query-private-alias.expected.nul"
  cmp \
    "$test_root/query-private-alias.expected.nul" \
    "$record_dir/query-private-alias.argv.nul"
fi

for suffix in preview-thunk debug; do
  preview_output="$test_root/route.$suffix.dylib"
  preview_args=(
    -target arm64-apple-ios15.0-simulator
    -isysroot "$sdk"
    -working-directory "$execroot"
    "@$valid_response"
    -Xlinker "@rpath/route.$suffix.dylib"
    -o "$preview_output"
  )
  run_capture "preview-$suffix" "$facade" "${preview_args[@]}"
  assert_status 73 "$(<"$test_root/preview-$suffix.status")" \
    "$suffix Preview route"
  printf '%s\0' "${preview_args[@]}" > "$test_root/preview-$suffix.expected.nul"
  cmp \
    "$test_root/preview-$suffix.expected.nul" \
    "$record_dir/preview-$suffix.argv.nul"
  require_absent "$preview_output"

  run_capture "cxx-preview-$suffix" "$cxx_facade" "${preview_args[@]}"
  assert_status 73 "$(<"$test_root/cxx-preview-$suffix.status")" \
    "C++ $suffix Preview route"
  printf '%s\0' --driver-mode=g++ "${preview_args[@]}" > \
    "$test_root/cxx-preview-$suffix.expected.nul"
  cmp \
    "$test_root/cxx-preview-$suffix.expected.nul" \
    "$record_dir/cxx-preview-$suffix.argv.nul"
  require_absent "$preview_output"
done

# Query takes priority even when the output has a Preview suffix.
readonly precedence_output="$test_root/precedence.preview-thunk.dylib"
readonly -a precedence_args=(
  -isysroot "$sdk"
  -working-directory "$execroot"
  "@$valid_response"
  -o "$precedence_output"
  -###
)
run_capture precedence "$facade" "${precedence_args[@]}"
assert_status 73 "$(<"$test_root/precedence.status")" "query precedence"
printf '%s\0' "${precedence_args[@]}" > "$test_root/precedence.expected.nul"
cmp "$test_root/precedence.expected.nul" "$record_dir/precedence.argv.nul"

for suffix in preview-thunk debug; do
  near_output="$test_root/near.$suffix.dylib.tmp"
  near_dependency_info="$test_root/near-$suffix"_dependency_info.dat
  run_capture "near-$suffix" \
    "$facade" \
    -o "$near_output" \
    -Xlinker -dependency_info -Xlinker "$near_dependency_info"
  assert_status 0 "$(<"$test_root/near-$suffix.status")" \
    "$suffix near-miss ordinary route"
  [[ -f "$near_dependency_info" ]] || fail "near-miss did not delegate to ld"
  require_absent "$near_output"
done

run_negative() {
  local name="$1"
  shift
  rm -f "$record_dir/$name.argv.nul"
  run_capture "$name" "$facade" "$@"
  assert_status 64 "$(<"$test_root/$name.status")" "$name"
  require_absent "$record_dir/$name.argv.nul"
}

run_negative missing-output \
  -isysroot "$sdk" -working-directory "$execroot" "@$valid_response" -###
run_negative incomplete-profile-runtime-query \
  -Xlinker -reproducible -isysroot "$sdk" \
  -fprofile-instr-generate -###
run_negative extended-profile-runtime-query \
  -target arm64-apple-ios15.0-simulator \
  -Xlinker -reproducible -isysroot "$sdk" \
  -fprofile-instr-generate -fapple-link-rtlib -###
run_negative conflicting-output \
  -isysroot "$sdk" \
  -o "$test_root/conflict.preview-thunk.dylib" \
  -o "$test_root/conflict.debug.dylib"
run_negative missing-sysroot \
  -isysroot -o "$test_root/missing-sysroot.preview-thunk.dylib"
run_negative duplicate-sysroot \
  -isysroot "$sdk" -isysroot "$sdk" \
  -o "$test_root/duplicate-sysroot.preview-thunk.dylib"
run_negative missing-working-directory \
  -isysroot "$sdk" "@$valid_response" -o "$query_output" -###
run_negative duplicate-working-directory \
  -isysroot "$sdk" \
  -working-directory "$execroot" -working-directory "$execroot" \
  "@$valid_response" -o "$query_output" -###
run_negative duplicate-query-option \
  -isysroot "$sdk" -working-directory "$execroot" \
  "@$valid_response" -o "$query_output" -### -###
run_negative joined-preview-output \
  -isysroot "$sdk" -working-directory "$execroot" \
  "@$valid_response" "-o$test_root/joined.preview-thunk.dylib"
readonly non_execroot="$test_root/not an execroot"
mkdir -p "$non_execroot"
run_negative invalid-working-directory \
  -isysroot "$sdk" -working-directory "$non_execroot" \
  "@$valid_response" -o "$query_output" -###

readonly nested_response="$test_root/nested.params"
printf '@%s\n' "$valid_response" > "$nested_response"
run_negative nested-response \
  -isysroot "$sdk" -working-directory "$execroot" \
  "@$nested_response" -o "$query_output" -###

readonly linked_binary_response="$test_root/linked-binary.params"
printf 'LINKED_BINARY=bazel-out/App\n' > "$linked_binary_response"
run_negative linked-binary-response \
  -isysroot "$sdk" -working-directory "$execroot" \
  "@$linked_binary_response" -o "$query_output" -###

readonly malformed_abi_response="$test_root/malformed-abi.params"
printf '%s\n' -objc_abi_version -Xlinker 2 > "$malformed_abi_response"
run_negative malformed-abi-response \
  -isysroot "$sdk" -working-directory "$execroot" \
  "@$malformed_abi_response" -o "$query_output" -###

readonly malformed_lto_response="$test_root/malformed-lto.params"
printf '%s\n' -Xlinker -object_path_lto -Xlinker > "$malformed_lto_response"
run_negative malformed-lto-response \
  -isysroot "$sdk" -working-directory "$execroot" \
  "@$malformed_lto_response" -o "$query_output" -###

echo PASS
