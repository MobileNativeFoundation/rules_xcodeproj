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
test_root="$(mktemp -d "${TMPDIR:-/tmp}/preview-framework-tests.XXXXXX")"
readonly test_root
export DERIVED_FILE_DIR="$test_root/default-derived"
trap 'rm -rf "$test_root"' EXIT

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

echo "PASS"
