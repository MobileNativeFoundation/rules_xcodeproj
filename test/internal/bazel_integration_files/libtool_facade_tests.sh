#!/bin/bash

set -euo pipefail

fail() {
  echo >&2 "FAIL: $*"
  exit 1
}

readonly repo_root="$TEST_SRCDIR/$TEST_WORKSPACE"
readonly facade="$repo_root/xcodeproj/internal/bazel_integration_files/libtool"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/libtool-facade-tests.XXXXXX")"
readonly test_root
trap 'rm -rf "$test_root"' EXIT

[[ -x "$facade" ]] || fail "packaged facade is not executable"
/bin/bash -n "$facade"

readonly product="$test_root/libSubject.a"
readonly dependency_info="$test_root/Subject_dependency_info.dat"
readonly framework_dir="$test_root/Framework Products"
mkdir -p "$framework_dir"
printf 'bazel-product\n' > "$product"

# Xcode 26 reads these canonical options while deriving its synthetic XOJIT
# image. The generated libtool facade must accept them without changing the
# already-staged Bazel archive.
"$facade" \
  -static \
  -o "$product" \
  -F"$framework_dir" \
  -framework Lottie \
  -rpath "$framework_dir" \
  -ObjC \
  "$dependency_info"

[[ "$(cat "$product")" == "bazel-product" ]] || \
  fail "Preview options changed the staged Bazel product"
[[ -f "$dependency_info" ]] || fail "dependency info was not created"
[[ "$(stat -f '%z' "$dependency_info")" == 3 ]] || \
  fail "dependency info has the wrong byte size"
[[ "$(od -An -tx1 "$dependency_info" | tr -d ' \n')" == "002000" ]] || \
  fail "dependency info has the wrong contents"

# Version queries retain the real-tool delegation contract.
readonly fake_bin="$test_root/bin"
readonly version_record="$test_root/version.argv"
mkdir -p "$fake_bin"
cat > "$fake_bin/libtool" <<'EOF'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$@" > "$VERSION_RECORD"
printf 'fake libtool version\n'
EOF
chmod 0755 "$fake_bin/libtool"

version_output="$(
  PATH="$fake_bin:$PATH" VERSION_RECORD="$version_record" \
    "$facade" -V -static
)"
[[ "$version_output" == "fake libtool version" ]] || \
  fail "version query did not delegate"
[[ "$(cat "$version_record")" == $'-V\n-static' ]] || \
  fail "version query arguments changed"

echo "PASS"
