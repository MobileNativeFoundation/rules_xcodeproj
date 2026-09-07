#!/bin/bash

set -euo pipefail

fail() {
  echo >&2 "FAIL: $*"
  exit 1
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local description="$3"
  [[ "$actual" == "$expected" ]] || \
    fail "$description: expected '$expected', got '$actual'"
}

assert_link() {
  local destination="$1"
  local source="$2"
  [[ -L "$destination" ]] || fail "missing symlink: $destination"
  [[ "$destination" -ef "$source" ]] || \
    fail "$destination does not resolve to $source"
}

readonly repo_root="$TEST_SRCDIR/$TEST_WORKSPACE"
readonly copy_outputs_script="$repo_root/xcodeproj/internal/bazel_integration_files/copy_outputs.sh"
readonly generator_template="$repo_root/xcodeproj/internal/templates/generate_bazel_dependencies.sh"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/preview-framework-tests.XXXXXX")"
readonly test_root
trap 'rm -rf "$test_root"' EXIT

run_generator_mode() {
  local name="$1"
  local enable_previews="$2"
  local native_previews="$3"
  local expected_groups="$4"
  local expected_config="$5"
  local clang_coverage_mapping="${6:-UNSET}"
  local case_dir="$test_root/generator-$name"
  local integration_dir="$case_dir/integration"
  local expected_output_groups
  local prefix
  local -a preview_environment=("RULES_XCODEPROJ_PREVIEW_TEST_ENVIRONMENT=1")
  local -a expected_prefixes

  mkdir -p \
    "$case_dir/source root" \
    "$case_dir/obj/Index.noindex" \
    "$integration_dir"

  sed 's|%swiftcopt%|@build_bazel_rules_swift//swift:copt|g' \
    "$generator_template" > "$integration_dir/generate_bazel_dependencies.sh"

  cat > "$case_dir/calculate_output_groups" <<'EOF'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$5" > "$CASE_DIR/groups"
IFS=',' read -r -a prefixes <<< "$5"
for prefix in "${prefixes[@]}"; do
  printf '//App:App\n%s //App:App configuration\n' "$prefix"
done
EOF
  chmod +x "$case_dir/calculate_output_groups"

  cat > "$integration_dir/bazel_build.sh" <<'EOF'
printf '%s\n' "$config" > "$CASE_DIR/config"
printf '%s\n' "${output_groups[@]}" > "$CASE_DIR/output_groups"
output_path="$CASE_DIR/output"
EOF

  if [[ "$enable_previews" != UNSET ]]; then
    preview_environment+=("ENABLE_PREVIEWS=$enable_previews")
  fi
  if [[ "$native_previews" != UNSET ]]; then
    preview_environment+=("BAZEL_NATIVE_PREVIEWS=$native_previews")
  fi
  if [[ "$clang_coverage_mapping" != UNSET ]]; then
    preview_environment+=("CLANG_COVERAGE_MAPPING=$clang_coverage_mapping")
  fi

  env \
    -u CLANG_COVERAGE_MAPPING \
    -u ENABLE_PREVIEWS \
    -u BAZEL_NATIVE_PREVIEWS \
    ENABLE_XOJIT_PREVIEWS=YES \
    "${preview_environment[@]}" \
    ACTION=build \
    BAZEL_CONFIG=dbg \
    BAZEL_INTEGRATION_DIR="$integration_dir" \
    BAZEL_OUT="$case_dir/bazel-out" \
    CALCULATE_OUTPUT_GROUPS_SCRIPT="$case_dir/calculate_output_groups" \
    CASE_DIR="$case_dir" \
    INDEX_DATA_STORE_DIR="$case_dir/obj/Index.noindex/DataStore" \
    OBJROOT="$case_dir/obj/Build/Intermediates.noindex" \
    PROJECT_DIR="$case_dir/source root" \
    SRCROOT="$case_dir/source root" \
    XCODE_VERSION_ACTUAL=2650 \
    bash "$integration_dir/generate_bazel_dependencies.sh"

  assert_equals "$expected_groups" "$(cat "$case_dir/groups")" \
    "$name output groups"
  assert_equals "$expected_config" "$(cat "$case_dir/config")" \
    "$name Bazel configuration"

  expected_output_groups=$'index_import\ntarget_ids_list'
  IFS=',' read -r -a expected_prefixes <<< "$expected_groups"
  for prefix in "${expected_prefixes[@]}"; do
    expected_output_groups+=$'\n'"$prefix //App:App configuration"
  done
  assert_equals \
    "$expected_output_groups" \
    "$(cat "$case_dir/output_groups")" \
    "$name output groups passed to bazel_build.sh"
}

# Xcode also sets ENABLE_XOJIT_PREVIEWS for ordinary Debug builds. All rows
# below deliberately export it; only the explicit configuration opts in.
if env ACTION=install BAZEL_NATIVE_PREVIEWS=YES bash "$generator_template" \
  >"$test_root/archive.stdout" 2>"$test_root/archive.stderr"; then
  fail "Preview configuration allowed an archive"
fi
grep -q "Preview configurations cannot archive" "$test_root/archive.stderr" || \
  fail "missing Preview archive diagnostic"

run_generator_mode unset UNSET UNSET bp _dbg_build
run_generator_mode ordinary NO NO bp _dbg_build
run_generator_mode coverage NO NO bp dbg_coverage YES
run_generator_mode legacy YES NO bc,bf,bp,bl dbg_swiftuipreviews
run_generator_mode xojit NO YES bc,bf,bl dbg_swiftuipreviews
run_generator_mode xojit-coverage NO YES bc,bf,bl dbg_swiftuipreviews YES
run_generator_mode both YES NO bc,bf,bp,bl dbg_swiftuipreviews

readonly fake_integration_dir="$test_root/copy-integration"
mkdir -p "$fake_integration_dir"
cat > "$fake_integration_dir/rsync" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$fake_integration_dir/rsync"

readonly binary_case="$test_root/copy-binary"
readonly binary_source_dir="$binary_case/product parent"
readonly binary_source="$binary_source_dir/libProduct.library.a"
readonly binary_destination_dir="$binary_case/build products"
mkdir -p "$binary_source_dir" "$binary_destination_dir"
printf 'archive' > "$binary_source"
env \
  ACTION=build \
  BAZEL_INTEGRATION_DIR="$fake_integration_dir" \
  BAZEL_OUTPUTS_PRODUCT="$binary_source" \
  BAZEL_OUTPUTS_PRODUCT_BASENAME=libProduct.library.a \
  FULL_PRODUCT_NAME=libProduct.library.a \
  PRODUCT_NAME=Product.library \
  TARGET_BUILD_DIR="$binary_destination_dir" \
  bash "$copy_outputs_script" _ ""
assert_link "$binary_destination_dir/libProduct.library.a" "$binary_source"
[[ ! -e "$binary_destination_dir/Product.library" ]] || \
  fail "binary product was staged under PRODUCT_NAME instead of FULL_PRODUCT_NAME"

run_relative_product_copy_mode() {
  local case_dir="$1"
  local enable_previews="$2"
  local native_previews="$3"
  local product_state="$4"
  local product_basename="${5:-libProduct.library.a}"
  local project_dir="$case_dir/project dir"
  local srcroot="$case_dir/source root"
  local relative_product="bazel-out/bin/App/$product_basename"
  local product="$project_dir/$relative_product"
  local stale_product="$case_dir/stale outputs/bin/App/$product_basename"
  local integration_dir="$fake_integration_dir"

  mkdir -p "${product%/*}" "${stale_product%/*}" "$srcroot" \
    "$case_dir/build products"
  if [[ "$product_basename" == *.app ]]; then
    integration_dir="$repo_root/xcodeproj/internal/bazel_integration_files"
    mkdir -p "$stale_product"
    printf 'stale app' > "$stale_product/Info.plist"
  else
    printf 'stale archive' > "$stale_product"
  fi
  ln -s "$case_dir/stale outputs" "$srcroot/bazel-out"
  if [[ "$product_state" == PRESENT ]]; then
    if [[ "$product_basename" == *.app ]]; then
      mkdir -p "$product"
      printf 'selected app' > "$product/Info.plist"
    else
      printf 'selected archive' > "$product"
    fi
  elif [[ "$product_state" == DANGLING ]]; then
    ln -s "$case_dir/missing archive" "$product"
  fi

  (
    cd "$srcroot"
    env \
      ACTION=build \
      BAZEL_INTEGRATION_DIR="$integration_dir" \
      BAZEL_OUTPUTS_PRODUCT="$relative_product" \
      BAZEL_OUTPUTS_PRODUCT_BASENAME="$product_basename" \
      ENABLE_PREVIEWS="$enable_previews" \
      ENABLE_XOJIT_PREVIEWS=YES \
      BAZEL_NATIVE_PREVIEWS="$native_previews" \
      FULL_PRODUCT_NAME="$product_basename" \
      PRODUCT_NAME=Product.library \
      PROJECT_DIR="$project_dir" \
      SRCROOT="$srcroot" \
      TARGET_BUILD_DIR="$case_dir/build products" \
      bash "$copy_outputs_script" _ ""
  )
}

for mode in ordinary legacy both; do
  enable_previews=NO
  native_previews=NO
  if [[ "$mode" != ordinary ]]; then enable_previews=YES; fi
  # Even legacy + shared-XOJIT does not opt into native configuration ownership.
  relative_case="$test_root/copy-relative-$mode-present"
  run_relative_product_copy_mode \
    "$relative_case" "$enable_previews" "$native_previews" PRESENT
  assert_link \
    "$relative_case/build products/libProduct.library.a" \
    "$relative_case/project dir/bazel-out/bin/App/libProduct.library.a"

  relative_app_case="$test_root/copy-relative-app-$mode-present"
  run_relative_product_copy_mode \
    "$relative_app_case" "$enable_previews" "$native_previews" PRESENT App.app
  assert_equals "selected app" \
    "$(cat "$relative_app_case/build products/App.app/Info.plist")" \
    "$mode top-level app came from PROJECT_DIR"

  for product_state in MISSING DANGLING; do
    for product_basename in libProduct.library.a App.app; do
      relative_case="$test_root/copy-relative-$mode-$product_state-$product_basename"
      if run_relative_product_copy_mode \
        "$relative_case" "$enable_previews" "$native_previews" \
        "$product_state" "$product_basename" \
        >"$test_root/relative.stdout" 2>"$test_root/relative.stderr"; then
        fail "$mode accepted a $product_state PROJECT_DIR product"
      fi
      grep -q "Bazel output product is not materialized" "$test_root/relative.stderr" || \
        fail "$mode did not diagnose the $product_state PROJECT_DIR product"
      [[ ! -e "$relative_case/build products/$product_basename" && \
         ! -L "$relative_case/build products/$product_basename" ]] || \
        fail "$mode copied a stale SRCROOT product"
    done
  done
done

make_framework() {
  local framework="$1"
  local executable_name="${framework##*/}"
  executable_name="${executable_name%.framework}"
  mkdir -p "$framework/Resources"
  printf 'binary' > "$framework/$executable_name"
  printf 'plist' > "$framework/Info.plist"
  printf 'resource' > "$framework/Resources/value.txt"
}

run_binary_copy_mode() {
  local case_dir="$1"
  local enable_previews="$2"
  local native_previews="$3"
  local preview_framework_paths="$4"
  local source_dir="$case_dir/product parent"
  local source="$source_dir/libStatic.a"

  mkdir -p "$source_dir" "$case_dir/build products"
  printf 'archive' > "$source"
  env \
    ACTION=build \
    BAZEL_INTEGRATION_DIR="$fake_integration_dir" \
    BAZEL_OUTPUTS_PRODUCT="$source" \
    BAZEL_OUTPUTS_PRODUCT_BASENAME=libStatic.a \
    ENABLE_PREVIEWS="$enable_previews" \
    BAZEL_NATIVE_PREVIEWS="$native_previews" \
    FULL_PRODUCT_NAME=libStatic.a \
    PREVIEW_FRAMEWORK_PATHS="$preview_framework_paths" \
    PRODUCT_NAME=Static \
    TARGET_BUILD_DIR="$case_dir/build products" \
    WRAPPER_NAME=libStatic.a \
    bash "$copy_outputs_script" _ ""
}

run_copy_mode() {
  local case_dir="$1"
  local enable_previews="$2"
  local native_previews="$3"
  local preview_framework_paths="$4"

  mkdir -p "$case_dir/product parent/Product.framework"
  env \
    ACTION=build \
    BAZEL_INTEGRATION_DIR="$fake_integration_dir" \
    BAZEL_OUTPUTS_PRODUCT="$case_dir/product parent/Product.framework" \
    BAZEL_OUTPUTS_PRODUCT_BASENAME=Product.framework \
    ENABLE_PREVIEWS="$enable_previews" \
    BAZEL_NATIVE_PREVIEWS="$native_previews" \
    PREVIEW_FRAMEWORK_PATHS="$preview_framework_paths" \
    PRODUCT_NAME=Product \
    TARGET_BUILD_DIR="$case_dir/build products" \
    WRAPPER_NAME=Product.framework \
    bash "$copy_outputs_script" _ ""
}

run_missing_product_copy_mode() {
  local case_dir="$1"
  local enable_previews="$2"
  local native_previews="$3"
  local preview_framework_paths="$4"

  mkdir -p "$case_dir/build products"
  env \
    ACTION=build \
    BAZEL_INTEGRATION_DIR="$fake_integration_dir" \
    BAZEL_OUTPUTS_PRODUCT="$case_dir/missing parent/Product.framework" \
    BAZEL_OUTPUTS_PRODUCT_BASENAME=Product.framework \
    ENABLE_PREVIEWS="$enable_previews" \
    BAZEL_NATIVE_PREVIEWS="$native_previews" \
    FULL_PRODUCT_NAME=Product.framework \
    PREVIEW_FRAMEWORK_PATHS="$preview_framework_paths" \
    PRODUCT_NAME=Product \
    TARGET_BUILD_DIR="$case_dir/build products" \
    WRAPPER_NAME=Product.framework \
    bash "$copy_outputs_script" _ ""
}

readonly framework_root="$test_root/framework sources"
readonly first_framework="$framework_root/First Framework.framework"
readonly second_framework="$framework_root/Second.framework"
make_framework "$first_framework"
make_framework "$second_framework"
readonly preview_paths="\"$first_framework\" \"$second_framework\""

readonly missing_ordinary_product_case="$test_root/copy-missing-ordinary-product"
if run_missing_product_copy_mode \
  "$missing_ordinary_product_case" \
  NO \
  NO \
  "$preview_paths" \
  >"$test_root/missing-ordinary-product.stdout" \
  2>"$test_root/missing-ordinary-product.stderr"; then
  fail "ordinary build accepted a missing Bazel output product"
fi
grep -q "Bazel output product is not materialized" \
  "$test_root/missing-ordinary-product.stderr" || \
  fail "missing ordinary product diagnostic was not emitted"

readonly missing_legacy_product_case="$test_root/copy-missing-legacy-product"
if run_missing_product_copy_mode \
  "$missing_legacy_product_case" \
  YES \
  NO \
  "$preview_paths" \
  >"$test_root/missing-legacy-product.stdout" \
  2>"$test_root/missing-legacy-product.stderr"; then
  fail "legacy Preview build accepted a missing Bazel output product"
fi
grep -q "Bazel output product is not materialized" \
  "$test_root/missing-legacy-product.stderr" || \
  fail "missing legacy Preview product diagnostic was not emitted"

readonly missing_xojit_product_case="$test_root/copy-missing-xojit-product"
run_missing_product_copy_mode \
  "$missing_xojit_product_case" \
  NO \
  YES \
  "$preview_paths"
assert_link \
  "$missing_xojit_product_case/build products/First Framework.framework" \
  "$first_framework"
assert_link \
  "$missing_xojit_product_case/build products/Second.framework" \
  "$second_framework"
[[ ! -e "$missing_xojit_product_case/build products/Product.framework" ]] || \
  fail "XOJIT copied a product that Xcode owns"

readonly binary_ordinary_case="$test_root/copy-binary-ordinary"
run_binary_copy_mode "$binary_ordinary_case" NO NO "$preview_paths"
assert_link \
  "$binary_ordinary_case/build products/libStatic.a" \
  "$binary_ordinary_case/product parent/libStatic.a"
[[ ! -e "$binary_ordinary_case/build products/First Framework.framework" ]] || \
  fail "ordinary binary build staged a Preview framework"
readonly binary_legacy_case="$test_root/copy-binary-legacy"
run_binary_copy_mode "$binary_legacy_case" YES NO "$preview_paths"
[[ ! -e "$binary_legacy_case/build products/First Framework.framework" ]] || \
  fail "legacy binary build staged a direct Preview framework"
[[ ! -e "$binary_legacy_case/build products/libStatic.a/SwiftUIPreviewsFrameworks" ]] || \
  fail "legacy binary build staged a nested Preview framework"
readonly binary_xojit_case="$test_root/copy-binary-xojit"
run_binary_copy_mode "$binary_xojit_case" NO YES "$preview_paths"
assert_link \
  "$binary_xojit_case/build products/First Framework.framework" \
  "$first_framework"
assert_link \
  "$binary_xojit_case/build products/Second.framework" \
  "$second_framework"
[[ -f "$binary_xojit_case/build products/First Framework.framework/Resources/value.txt" ]] || \
  fail "XOJIT binary framework symlink is incomplete"
[[ ! -e "$binary_xojit_case/build products/libStatic.a" ]] || \
  fail "XOJIT copied a stale Bazel binary product"
readonly ordinary_case="$test_root/copy-ordinary"
run_copy_mode "$ordinary_case" NO NO "$preview_paths"
[[ ! -e "$ordinary_case/build products/First Framework.framework" ]] || \
  fail "ordinary build staged a direct Preview framework"
[[ ! -e "$ordinary_case/build products/Product.framework/SwiftUIPreviewsFrameworks" ]] || \
  fail "ordinary build staged nested Preview frameworks"

readonly legacy_case="$test_root/copy-legacy"
run_copy_mode "$legacy_case" YES NO "$preview_paths"
readonly legacy_destination="$legacy_case/build products/Product.framework/SwiftUIPreviewsFrameworks"
assert_link "$legacy_destination/First Framework.framework" "$first_framework"
assert_link "$legacy_destination/Second.framework" "$second_framework"
[[ -f "$legacy_destination/First Framework.framework/Info.plist" ]] || \
  fail "legacy framework symlink is incomplete"

readonly xojit_case="$test_root/copy-xojit"
run_copy_mode "$xojit_case" NO YES "$preview_paths"
assert_link "$xojit_case/build products/First Framework.framework" "$first_framework"
assert_link "$xojit_case/build products/Second.framework" "$second_framework"
[[ -f "$xojit_case/build products/First Framework.framework/Resources/value.txt" ]] || \
  fail "XOJIT framework symlink is incomplete"
[[ ! -e "$xojit_case/build products/Product.framework" ]] || \
  fail "XOJIT copied a stale Bazel bundle product"
run_copy_mode "$xojit_case" NO YES "$preview_paths"

# macOS imports expose a root executable symlink but load Versions/A at runtime.
# Staging the whole framework must preserve both paths and its resources.
readonly versioned_framework="$framework_root/Versioned.framework"
mkdir -p "$versioned_framework/Versions/A/Resources"
printf 'versioned binary' > "$versioned_framework/Versions/A/Versioned"
printf 'versioned plist' > "$versioned_framework/Versions/A/Resources/Info.plist"
ln -s A "$versioned_framework/Versions/Current"
ln -s Versions/Current/Versioned "$versioned_framework/Versioned"
ln -s Versions/Current/Resources "$versioned_framework/Resources"
readonly app_versioned_case="$test_root/copy-app-versioned-xojit"
env \
  ACTION=build \
  BAZEL_INTEGRATION_DIR="$fake_integration_dir" \
  BAZEL_OUTPUTS_PRODUCT="$app_versioned_case/missing/App.app" \
  BAZEL_OUTPUTS_PRODUCT_BASENAME=App.app \
  ENABLE_PREVIEWS=NO \
  BAZEL_NATIVE_PREVIEWS=YES \
  PREVIEW_FRAMEWORK_PATHS="\"$versioned_framework\"" \
  PRODUCT_NAME=App \
  TARGET_BUILD_DIR="$app_versioned_case/build products" \
  WRAPPER_NAME=App.app \
  bash "$copy_outputs_script" _ ""
readonly staged_versioned="$app_versioned_case/build products/Versioned.framework"
assert_link "$staged_versioned" "$versioned_framework"
[[ "$staged_versioned/Versioned" -ef "$staged_versioned/Versions/A/Versioned" ]] || \
  fail "versioned framework executable does not resolve through its root symlink"
assert_equals "versioned binary" "$(cat "$staged_versioned/Versions/A/Versioned")" \
  "versioned framework runtime executable"
assert_equals "versioned plist" "$(cat "$staged_versioned/Resources/Info.plist")" \
  "versioned framework metadata"
[[ ! -e "$app_versioned_case/build products/App.app" ]] || \
  fail "versioned framework staging copied the Bazel app product"

readonly concurrent_case="$test_root/copy-xojit-concurrent"
concurrent_pids=()
for concurrent_index in {1..8}; do
  run_copy_mode "$concurrent_case" NO YES "$preview_paths" \
    >"$test_root/concurrent-$concurrent_index.stdout" \
    2>"$test_root/concurrent-$concurrent_index.stderr" &
  concurrent_pids+=("$!")
done
for concurrent_pid in "${concurrent_pids[@]}"; do
  wait "$concurrent_pid"
done
assert_link \
  "$concurrent_case/build products/First Framework.framework" \
  "$first_framework"
assert_link \
  "$concurrent_case/build products/Second.framework" \
  "$second_framework"

readonly both_case="$test_root/copy-both"
run_copy_mode "$both_case" YES NO "$preview_paths"
assert_link \
  "$both_case/build products/Product.framework/SwiftUIPreviewsFrameworks/First Framework.framework" \
  "$first_framework"
[[ ! -e "$both_case/build products/First Framework.framework" ]] || \
  fail "legacy mode did not take precedence over XOJIT"

readonly missing_case="$test_root/copy-missing"
if run_copy_mode \
  "$missing_case" \
  NO \
  YES \
  "\"$first_framework\" \"$test_root/Missing.framework\"" \
  >"$test_root/missing.stdout" 2>"$test_root/missing.stderr"; then
  fail "missing Preview framework was accepted"
fi
grep -q "not a materialized directory" "$test_root/missing.stderr" || \
  fail "missing Preview framework diagnostic was not emitted"
[[ ! -e "$missing_case/build products" ]] || \
  fail "valid framework was staged before a later missing framework failed"

readonly malformed_case="$test_root/copy-malformed"
if run_copy_mode \
  "$malformed_case" \
  NO \
  YES \
  "\"$first_framework\" \"unterminated" \
  >"$test_root/malformed.stdout" 2>"$test_root/malformed.stderr"; then
  fail "malformed Preview framework paths were accepted"
fi
grep -q "Unable to parse Preview framework paths" "$test_root/malformed.stderr" || \
  fail "malformed Preview framework path diagnostic was not emitted"
[[ ! -e "$malformed_case/build products" ]] || \
  fail "malformed Preview framework paths left staged output"

readonly not_framework="$test_root/NotAFramework"
mkdir -p "$not_framework"
readonly non_framework_case="$test_root/copy-non-framework"
if run_copy_mode \
  "$non_framework_case" \
  NO \
  YES \
  "\"$not_framework\"" \
  >"$test_root/non-framework.stdout" 2>"$test_root/non-framework.stderr"; then
  fail "non-framework directory was accepted"
fi
grep -q "does not name a .framework" "$test_root/non-framework.stderr" || \
  fail "non-framework diagnostic was not emitted"

readonly conflicting_root="$test_root/conflicting sources"
readonly conflicting_one="$conflicting_root/one/Collision.framework"
readonly conflicting_two="$conflicting_root/two/Collision.framework"
make_framework "$conflicting_one"
make_framework "$conflicting_two"
readonly conflict_case="$test_root/copy-conflict"
if run_copy_mode \
  "$conflict_case" \
  NO \
  YES \
  "\"$conflicting_one\" \"$conflicting_two\"" \
  >"$test_root/conflict.stdout" 2>"$test_root/conflict.stderr"; then
  fail "conflicting Preview framework basenames were accepted"
fi
grep -q "same basename" "$test_root/conflict.stderr" || \
  fail "duplicate Preview framework basename diagnostic was not emitted"
[[ ! -e "$conflict_case/build products" ]] || \
  fail "duplicate Preview framework basenames left staged output"

readonly preexisting_case="$test_root/copy-preexisting-conflict"
readonly preexisting_destination="$preexisting_case/build products/Second.framework"
mkdir -p "${preexisting_destination%/*}"
ln -s "$first_framework" "$preexisting_destination"
if run_copy_mode \
  "$preexisting_case" \
  NO \
  YES \
  "$preview_paths" \
  >"$test_root/preexisting.stdout" 2>"$test_root/preexisting.stderr"; then
  fail "conflicting preexisting Preview framework destination was accepted"
fi
grep -q "points to a different source" "$test_root/preexisting.stderr" || \
  fail "preexisting Preview framework collision diagnostic was not emitted"
[[ ! -e "$preexisting_case/build products/First Framework.framework" ]] || \
  fail "framework was staged before a later preexisting conflict failed"
assert_link "$preexisting_destination" "$first_framework"
