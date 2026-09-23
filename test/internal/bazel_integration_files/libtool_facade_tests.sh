#!/bin/bash

set -euo pipefail

unset ENABLE_PREVIEWS ENABLE_XOJIT_PREVIEWS DERIVED_FILE_DIR

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

readonly preview_facade="$test_root/xojit/libtool"
mkdir -p "${preview_facade%/*}"
ln -s "$facade" "$preview_facade"

readonly product="$test_root/libSubject.a"
readonly dependency_info="$test_root/Subject_dependency_info.dat"
readonly framework_dir="$test_root/Framework Products"
mkdir -p "$framework_dir"
printf 'bazel-product\n' > "$product"

# Ordinary and legacy builds retain the already-staged Bazel archive.
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

# Pure XOJIT compiles the selected target with Xcode and needs a real archive,
# even on a cold build with no previously staged Bazel product.
readonly developer_dir="$test_root/Xcode With Spaces.app/Contents/Developer"
readonly sdk="$developer_dir/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
readonly real_libtool="$developer_dir/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool"
readonly native_record="$test_root/native.argv.nul"
readonly native_product="$test_root/libNative.a"
readonly native_dependency_info="$test_root/Native_dependency_info.dat"
readonly target_temp_dir="$test_root/Target With Spaces"
readonly derived_dir="$target_temp_dir/DerivedSources"
readonly metadata_response="$derived_dir/link.params"
readonly unknown_response="$test_root/unknown.params"
readonly other_response="$test_root/Other/link.params"
readonly filelist="$target_temp_dir/Objects-normal/arm64/Native.LinkFileList"
mkdir -p "${real_libtool%/*}" "$sdk" "$derived_dir" "${other_response%/*}" \
  "${filelist%/*}"
printf '%s\n' -ObjC -framework Example > "$metadata_response"
cp "$metadata_response" "$test_root/original-link.params"
printf '%s\n' 'native-object.o' > "$filelist"
printf '%s\n' 'other-native-object.o' > "$unknown_response"
printf '%s\n' 'another-native-object.o' > "$other_response"
cat > "$real_libtool" <<'EOF'
#!/bin/bash
set -euo pipefail
printf '%s\0' "$@" > "$NATIVE_RECORD"
if [[ "${NATIVE_FAIL:-}" == YES ]]; then
  echo >&2 "native libtool failure"
  exit 73
fi
while (( $# )); do
  case "$1" in
    -o) shift; printf 'native-archive\n' > "$1" ;;
    -dependency_info) shift; printf 'native-dependencies\n' > "$1" ;;
  esac
  shift
done
EOF
chmod 0755 "$real_libtool"

readonly -a native_args=(
  -static -arch_only arm64 -D -syslibroot "$sdk" "-L$sdk/usr/lib"
  -filelist "$filelist" "@$unknown_response" "@$other_response"
  -dependency_info "$native_dependency_info" -o "$native_product"
)
printf '%s\0' "${native_args[@]}" > "$test_root/expected-native.argv.nul"
[[ ! -e "$native_product" ]] || fail "cold product already exists"
# Actual Xcode native Libtool tasks export the deployment target, not Preview
# flags or DERIVED_FILE_DIR. NATIVE_RECORD is only the mock's output channel.
env -i IPHONEOS_DEPLOYMENT_TARGET=17.0 NATIVE_RECORD="$native_record" \
  "$preview_facade" "@$metadata_response" "${native_args[@]}"
[[ -f "$native_product" ]] || fail "cold XOJIT archive was not produced"
[[ "$(cat "$native_product")" == native-archive ]] || \
  fail "XOJIT did not use the native archiver"
cmp "$test_root/expected-native.argv.nul" "$native_record"
cmp "$test_root/original-link.params" "$metadata_response"
[[ "$(cat "$native_dependency_info")" == native-dependencies ]] || \
  fail "XOJIT replaced native dependency info with stub metadata"

# The companion calculation works for another variant/architecture too.
readonly variant_filelist="$target_temp_dir/Objects-profile/x86_64/Native.LinkFileList"
env -i NATIVE_RECORD="$native_record" "$preview_facade" \
  -static -syslibroot "$sdk" -filelist "$variant_filelist" "@$metadata_response"
printf '%s\0' -static -syslibroot "$sdk" -filelist "$variant_filelist" \
  > "$test_root/expected-variant.argv.nul"
cmp "$test_root/expected-variant.argv.nul" "$native_record"

# A missing filelist or an unrelated layout cannot establish response identity.
# Forward those invocations intact; native libtool owns their validity.
for layout in missing unrelated nested; do
  response_args=(-static -syslibroot "$sdk" "@$metadata_response")
  case "$layout" in
    unrelated) response_args+=(-filelist "$test_root/Native.LinkFileList") ;;
    nested) response_args+=(-filelist "${filelist%/*}/Nested/Native.LinkFileList") ;;
  esac
  env -i NATIVE_RECORD="$native_record" \
    "$preview_facade" "${response_args[@]}"
  printf '%s\0' "${response_args[@]}" > "$test_root/expected-unknown.argv.nul"
  cmp "$test_root/expected-unknown.argv.nul" "$native_record"
done

# Native tool resolution must not fall back to the globally selected Xcode.
for sysroot_case in missing invalid; do
  resolution_args=(-static)
  if [[ "$sysroot_case" == invalid ]]; then
    resolution_args+=(-syslibroot /not/an/Xcode.sdk)
  fi
  set +e
  env -i "$preview_facade" "${resolution_args[@]}" \
    > "$test_root/resolution.stdout" 2> "$test_root/resolution.stderr"
  resolution_status=$?
  set -e
  [[ "$resolution_status" == 64 ]] || \
    fail "$sysroot_case sysroot did not fail native tool resolution"
done

# Ordinary/legacy modes must not invoke native libtool, even when XOJIT is
# also enabled in legacy mode. They preserve the staged product and stub info.
cp "$native_record" "$test_root/unchanged-native.argv.nul"
for mode in ordinary explicit-no legacy legacy-xojit; do
  case "$mode" in
    ordinary) enable_previews=; enable_xojit= ;;
    explicit-no) enable_previews=NO; enable_xojit=NO ;;
    legacy) enable_previews=YES; enable_xojit= ;;
    legacy-xojit) enable_previews=YES; enable_xojit=YES ;;
  esac
  ENABLE_PREVIEWS="$enable_previews" ENABLE_XOJIT_PREVIEWS="$enable_xojit" \
    DERIVED_FILE_DIR="$derived_dir" NATIVE_RECORD="$native_record" \
    "$facade" "@$metadata_response" -o "$product" "$dependency_info"
  [[ "$(cat "$product")" == bazel-product ]] || fail "$mode changed product"
  cmp "$test_root/unchanged-native.argv.nul" "$native_record"
  [[ "$(od -An -tx1 "$dependency_info" | tr -d ' \n')" == "002000" ]] || \
    fail "$mode changed dependency-info behavior"
done

# Native failure and diagnostics must propagate, not report a stub success.
set +e
env -i NATIVE_RECORD="$native_record" NATIVE_FAIL=YES \
  "$preview_facade" "@$metadata_response" "${native_args[@]}" \
  > "$test_root/failure.stdout" 2> "$test_root/failure.stderr"
native_status=$?
set -e
[[ "$native_status" == 73 ]] || fail "native failure status was not preserved"
[[ "$(cat "$test_root/failure.stderr")" == 'native libtool failure' ]] || \
  fail "native failure diagnostics were not preserved"

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

version_output="$(
  env -i PATH="$fake_bin:/usr/bin:/bin" \
    VERSION_RECORD="$version_record" "$preview_facade" -V -static
)"
[[ "$version_output" == "fake libtool version" ]] || \
  fail "XOJIT version query did not retain delegation"
[[ "$(cat "$version_record")" == $'-V\n-static' ]] || \
  fail "XOJIT version query arguments changed"

# Exercise the real installer template with inert inputs. The Preview entry
# point must remain an executable symlink after both initial install and update.
readonly installer_template="$repo_root/xcodeproj/internal/templates/installer.sh"
readonly installer_inputs="$test_root/Installer Inputs"
readonly installed_project="$test_root/Installed Project.xcodeproj"
mkdir -p "$installer_inputs/schemes"
: > "$installer_inputs/empty"
cp "$facade" "$installer_inputs/libtool"
printf '#!/bin/bash\nexit 0\n' > "$installer_inputs/rsync"
chmod 0755 "$installer_inputs/rsync"
sed \
  -e 's/%bazel_integration_files%/(libtool rsync)/g' \
  -e 's/%rsync%/rsync/g' \
  -e 's/%xcschemes%/schemes/g' \
  -e 's/%output_path%/Installed Project.xcodeproj/g' \
  -e 's/%[a-z_]*%/empty/g' \
  "$installer_template" > "$installer_inputs/install.sh"
for _ in 1 2; do
  (
    cd "$installer_inputs"
    /bin/bash install.sh \
      --bazel_env "$installer_inputs/empty" \
      --bazel_path /usr/bin/false \
      --xcodeproj_bazelrc "$installer_inputs/empty" \
      --destination "$installed_project" \
      --execution_root "$test_root/output/execroot/_main" > /dev/null
  )
  installed_facade="$installed_project/rules_xcodeproj/bazel/xojit/libtool"
  [[ -L "$installed_facade" && -x "$installed_facade" ]] || \
    fail "installer omitted executable Preview entry point"
  [[ "$(readlink "$installed_facade")" == ../libtool ]] || \
    fail "installer changed the Preview entry-point target"
  cmp "$facade" "$installed_facade"
done

echo "PASS"
