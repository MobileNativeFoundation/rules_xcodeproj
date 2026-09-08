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
export DERIVED_FILE_DIR="$test_root/default-derived"
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
run_generator_mode xojit NO YES bc,bf,bl,br dbg_swiftuipreviews
run_generator_mode xojit-coverage NO YES bc,bf,bl,br dbg_swiftuipreviews YES
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

run_resource_copy_mode() {
  local case_dir="$1" owner="$2" paths="$3"
  env \
    ACTION="${6:-build}" \
    BAZEL_INTEGRATION_DIR="${7:-$repo_root/xcodeproj/internal/bazel_integration_files}" \
    BAZEL_OUTPUTS_PRODUCT= \
    BAZEL_NATIVE_PREVIEWS="${4:-YES}" \
    ENABLE_PREVIEWS="${5:-NO}" \
    ENABLE_XOJIT_PREVIEWS=YES \
    DERIVED_FILE_DIR="$case_dir/Derived/$owner" \
    PREVIEW_FRAMEWORK_PATHS= \
    PREVIEW_RESOURCE_BUNDLE_PATHS="$paths" \
    TARGET_BUILD_DIR="$case_dir/build products/Features/Example" \
    UNLOCALIZED_RESOURCES_FOLDER_PATH="${8:-}" \
    WRAPPER_EXTENSION="${9:-}" \
    bash "$copy_outputs_script" _ ""
}

readonly resource_case="$test_root/resource-copy"
readonly resource_a="$resource_case/sources/First Resources.bundle"
readonly resource_b="$resource_case/sources/Second.bundle"
readonly resource_destination="$resource_case/build products/Features/Example"
mkdir -p "$resource_a/en.lproj" "$resource_a/Model.momd" "$resource_b/Nested.bundle"
printf 'plist' > "$resource_a/Info.plist"
printf 'localized-content' > "$resource_a/en.lproj/Localizable.strings"
printf 'compiled-model' > "$resource_a/Model.momd/contents"
printf 'compiled-assets' > "$resource_a/Assets.car"
printf 'plist' > "$resource_b/Info.plist"
printf 'nested-plist' > "$resource_b/Nested.bundle/Info.plist"
printf 'nested-content' > "$resource_b/Nested.bundle/value.txt"
touch -t 202001020304.05 "$resource_a/Assets.car"
readonly resource_paths="\"$resource_a\" \"$resource_b\""

# App-owned Previews load resources from Bundle.main, not product siblings.
for app_resources in "Mac App.app/Contents/Resources" "IOS App.app"; do
  app_case="$test_root/app-resources/$app_resources"
  app_destination="$app_case/build products/Features/Example/$app_resources"
  run_resource_copy_mode "$app_case" App "$resource_paths" NO YES build "" "$app_resources" app
  run_resource_copy_mode "$app_case" App "$resource_paths" YES NO indexbuild "" "$app_resources" app
  [[ ! -e "$app_destination" ]] || fail "non-native app resources were copied"
  run_resource_copy_mode "$app_case" App "$resource_paths" YES NO build "" "$app_resources" app
  diff -r "$resource_a" "$app_destination/First Resources.bundle"
  diff -r "$resource_b" "$app_destination/Second.bundle"
  mkdir "$app_destination/Unknown.bundle"
  run_resource_copy_mode "$app_case" App "" YES NO build "" "$app_resources" app
  [[ ! -e "$app_destination/First Resources.bundle" ]] || fail "stale app resources survived"
  [[ -d "$app_destination/Unknown.bundle" ]] || fail "unknown app resources were removed"
done

# Neither legacy/XOJIT flags nor indexing opt into native resource ownership.
run_resource_copy_mode "$resource_case" A "$resource_paths" NO NO
run_resource_copy_mode "$resource_case" A "$resource_paths" NO YES
run_resource_copy_mode "$resource_case" A "$resource_paths" YES NO indexbuild
[[ ! -e "$resource_destination" ]] || fail "non-native resource build mutated destination"

run_resource_copy_mode "$resource_case" A "$resource_paths"
diff -r "$resource_a" "$resource_destination/First Resources.bundle"
diff -r "$resource_b" "$resource_destination/Second.bundle"
[[ ! -e "$resource_destination/Features" ]] || fail "resource package path was duplicated"
resource_mtime="$(stat -f %m "$resource_destination/First Resources.bundle/Assets.car")"
run_resource_copy_mode "$resource_case" A "$resource_paths"
assert_equals "$resource_mtime" \
  "$(stat -f %m "$resource_destination/First Resources.bundle/Assets.car")" \
  "unchanged resource timestamp"
printf 'stale-content' > "$resource_destination/First Resources.bundle/stale.txt"
mv "$resource_b/Nested.bundle/value.txt" "$resource_case/removed.txt"
run_resource_copy_mode "$resource_case" A "$resource_paths"
[[ ! -e "$resource_destination/First Resources.bundle/stale.txt" ]] || fail "stale bundle content survived"
[[ ! -e "$resource_destination/Second.bundle/Nested.bundle/value.txt" ]] || fail "removed nested resource survived"

# Unknown neighbors survive [A,B] -> [A] -> [].
mkdir "$resource_destination/Unknown.bundle"
printf 'unknown' > "$resource_destination/Unknown.bundle/value"
run_resource_copy_mode "$resource_case" A "\"$resource_a\""
[[ ! -e "$resource_destination/Second.bundle" ]] || fail "owned removed bundle survived"
[[ -f "$resource_destination/First Resources.bundle/Info.plist" ]] || fail "retained bundle disappeared"
run_resource_copy_mode "$resource_case" A ""
[[ ! -e "$resource_destination/First Resources.bundle" ]] || fail "empty closure retained owned bundle"
[[ "$(cat "$resource_destination/Unknown.bundle/value")" == unknown ]] || fail "unknown neighbor changed"

# Two target phases in the same package can share one exact source.
run_resource_copy_mode "$resource_case" Library "\"$resource_a\""
run_resource_copy_mode "$resource_case" App "\"$resource_a\""
run_resource_copy_mode "$resource_case" Library ""
diff -r "$resource_a" "$resource_destination/First Resources.bundle"
run_resource_copy_mode "$resource_case" App ""
[[ ! -e "$resource_destination/First Resources.bundle" ]] || fail "last owner failed to remove stale copy"

run_resource_copy_mode "$resource_case" Library "\"$resource_a\""
readonly different_source="$resource_case/other/First Resources.bundle"
mkdir -p "$different_source"
printf 'other-plist' > "$different_source/Info.plist"
if run_resource_copy_mode "$resource_case" App "\"$different_source\"" \
  > "$resource_case/different.out" 2> "$resource_case/different.err"; then
  fail "same basename from a different source was accepted"
fi
grep -q 'different source' "$resource_case/different.err" || fail "different source was not diagnosed"
diff -r "$resource_a" "$resource_destination/First Resources.bundle"
run_resource_copy_mode "$resource_case" Library ""

# Existing directories, files and links are not adopted, even if the contents match.
for destination_kind in directory file symlink; do
  unknown_case="$test_root/unknown-resource-$destination_kind"
  unknown_destination="$unknown_case/build products/Features/Example"
  mkdir -p "$unknown_destination"
  case "$destination_kind" in
    directory) cp -R "$resource_a" "$unknown_destination" ;;
    file) printf 'user-file' > "$unknown_destination/First Resources.bundle" ;;
    symlink) ln -s "$resource_a" "$unknown_destination/First Resources.bundle" ;;
  esac
  if run_resource_copy_mode "$unknown_case" A "\"$resource_a\"" \
    > "$unknown_case/failure.out" 2> "$unknown_case/failure.err"; then
    fail "unowned $destination_kind was adopted"
  fi
  grep -q 'not owned' "$unknown_case/failure.err" || fail "unknown destination was not diagnosed"
  case "$destination_kind" in
    directory) diff -r "$resource_a" "$unknown_destination/First Resources.bundle" ;;
    file) [[ "$(cat "$unknown_destination/First Resources.bundle")" == user-file ]] || fail "unknown file changed" ;;
    symlink) assert_link "$unknown_destination/First Resources.bundle" "$resource_a" ;;
  esac
done

# External replacement invalidates our directory identity, including cleanup.
run_resource_copy_mode "$resource_case" A "\"$resource_a\""
mv "$resource_destination/First Resources.bundle" "$resource_case/original-copy.bundle"
mkdir "$resource_destination/First Resources.bundle"
printf 'replacement' > "$resource_destination/First Resources.bundle/value"
run_resource_copy_mode "$resource_case" A ""
[[ "$(cat "$resource_destination/First Resources.bundle/value")" == replacement ]] || fail "replaced stale destination was removed"

# Validate all inputs before touching any of them.
readonly invalid_case="$test_root/invalid-resources"
readonly invalid_source="$invalid_case/sources/Missing.bundle"
mkdir -p "$invalid_source"
if run_resource_copy_mode "$invalid_case" A "\"$resource_a\" \"$invalid_source\"" \
  > "$invalid_case/failure.out" 2> "$invalid_case/failure.err"; then
  fail "bundle without Info.plist was accepted"
fi
[[ ! -e "$invalid_case/build products/Features/Example/First Resources.bundle" ]] || fail "invalid closure partially copied"
if run_resource_copy_mode "$invalid_case" A "\"$resource_a\" \"$resource_a\"" \
  > "$invalid_case/duplicate.out" 2> "$invalid_case/duplicate.err"; then
  fail "duplicate resource basename was accepted"
fi
[[ ! -e "$invalid_case/build products/Features/Example/First Resources.bundle" ]] || fail "duplicate closure partially copied"

# A failed copy is recorded before rsync, and a later build can finish it.
readonly partial_case="$test_root/partial-resources"
readonly failing_integration="$partial_case/integration"
mkdir -p "$failing_integration"
printf '#!/bin/bash\nexit 42\n' > "$failing_integration/rsync"
chmod +x "$failing_integration/rsync"
if run_resource_copy_mode "$partial_case" A "\"$resource_a\"" YES NO build "$failing_integration" \
  > "$partial_case/failure.out" 2> "$partial_case/failure.err"; then
  fail "rsync failure was swallowed"
fi
[[ -f "$partial_case/build products/Features/Example/.rules_xcodeproj_preview_resource_bundles" ]] || fail "partial copy ownership was lost"
run_resource_copy_mode "$partial_case" A "\"$resource_a\""
diff -r "$resource_a" "$partial_case/build products/Features/Example/First Resources.bundle"
run_resource_copy_mode "$partial_case" A ""
[[ ! -e "$partial_case/build products/Features/Example/First Resources.bundle" ]] || fail "recovered copy was not cleaned"
