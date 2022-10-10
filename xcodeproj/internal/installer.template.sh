#!/bin/bash

set -euo pipefail

# Functions

# Echos the provided message to stderr and exits with an error (1)
fail() {
  local msg="${1:-}"
  shift 1
  while (("$#")); do
    msg="${msg:-}"$'\n'"${1}"
    shift 1
  done
  echo >&2 "${msg}"
  exit 1
}

# Process Args

for_fixture=0

while (("$#")); do
  case "${1}" in
    "--bazel_path")
      bazel_path="${2}"
      shift 2
      ;;
    "--bazelrc")
      bazelrc="${2}"
      shift 2
      ;;
    "--destination")
      dest="${2}"
      shift 2
      ;;
    "--extra_flags_bazelrc")
      extra_flags_bazelrc="${2}"
      shift 2
      ;;
    "--for_fixture")
      for_fixture=1
      shift
      ;;
    *)
      fail "Unrecognized argument: ${1}"
      ;;
  esac
done

if [[ -z "${bazel_path:-}" ]]; then
  fail "Missing required argument: --bazel_path"
fi

# Resolve the inputs
readonly src="$PWD/%source_path%"
readonly swiftc_stub="$PWD/%swiftc_stub%"

# Resolve the destination
[[ -z "${dest:-}" ]] \
  && [[ -n "${BUILD_WORKSPACE_DIRECTORY:-}" ]] \
  && dest="$BUILD_WORKSPACE_DIRECTORY/%output_path%"
[[ -n "${dest:-}" ]] || fail "A destination for the Xcode project was not set"
dest_dir="$(dirname "${dest}")"
[[ -d "${dest_dir}" ]] || \
  fail "The destination directory does not exist or is not a directory" \
    "${dest_dir}"

# Sync over spec if requested
if [[ $for_fixture -eq 1 ]]; then
  readonly spec_src="$PWD/%spec_path%"
  readonly spec_dest="${dest%.xcodeproj}_spec.json"
  python3 -m json.tool "$spec_src" > "$spec_dest"
fi

# Sync over the project, changing the permissions to be writable

# Don't touch project.xcworkspace as that will make Xcode prompt
rsync \
  --archive \
  --copy-links \
  --chmod=u+w,F-x \
  --exclude=project.xcworkspace \
  --exclude=xcuserdata \
  --exclude=rules_xcodeproj/links \
  --delete \
  "$src/" "$dest/"

# Make scripts runnable
if [[ -d "$dest/rules_xcodeproj/bazel" ]]; then
  shopt -s nullglob
  chmod u+x "$dest/rules_xcodeproj/bazel/"*.{py,sh}
fi

# Copy over xcodeproj.bazelrc
cp "$bazelrc" "$dest/rules_xcodeproj/bazel/xcodeproj.bazelrc"
chmod u+w "$dest/rules_xcodeproj/bazel/xcodeproj.bazelrc"

# Copy over swiftc stub executable
readonly swiftc_stub_dest="$dest/rules_xcodeproj/bazel/swiftc"
if [[ $for_fixture -eq 1 ]]; then
  # TODO: Create a relative symlink
  touch "$swiftc_stub_dest"
else
  cp -c "$swiftc_stub" "$swiftc_stub_dest"
fi

# Copy over xcodeproj_extra_flags.bazelrc if it exists
# We can't include this file as an input to the generator, because it would
# require setting ` --@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:extra_*_flags`
# flags, which thrashes the analysis cache
if [[ -s "${extra_flags_bazelrc:-}" ]]; then
  cp "$extra_flags_bazelrc" "$dest/rules_xcodeproj/bazel/xcodeproj_extra_flags.bazelrc"
  chmod u+w "$dest/rules_xcodeproj/bazel/xcodeproj_extra_flags.bazelrc"
fi

# Copy over project.xcworkspace/contents.xcworkspacedata if needed
if [[ ! -f "$dest/project.xcworkspace/contents.xcworkspacedata" ]] || \
  ! cmp -s "$src/project.xcworkspace/contents.xcworkspacedata" "$dest/project.xcworkspace/contents.xcworkspacedata"
then
  mkdir -p "$dest/project.xcworkspace"
  cp "$src/project.xcworkspace/contents.xcworkspacedata" "$dest/project.xcworkspace/contents.xcworkspacedata"
  chmod u+w "$dest/project.xcworkspace/contents.xcworkspacedata"
fi

# Set desired project.xcworkspace data
workspace_data="$dest/project.xcworkspace/xcshareddata"
if [[ ! -d $workspace_data ]]; then
  mkdir -p "$workspace_data"
fi

readonly workspace_checks="$workspace_data/IDEWorkspaceChecks.plist"
readonly workspace_settings="$workspace_data/WorkspaceSettings.xcsettings"

readonly settings_files=(
  "$workspace_checks"
  "$workspace_settings"
)

for file in "${settings_files[@]}"; do
  if [[ ! -f $file ]]; then
    # Create an empty plist
    echo "{}" | plutil -convert xml1 -o "$file" -
  fi
done

# Prevent Xcode from doing work that slows down startup
plutil -replace IDEDidComputeMac32BitWarning -bool true "$workspace_checks"

# Configure the project to use Xcode's new build system.
plutil -remove BuildSystemType "$workspace_settings" > /dev/null || true

# Prevent Xcode from prompting the user to autocreate schemes for all targets
plutil -replace IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded -bool false "$workspace_settings"

# Create folder structure in bazel-out to work around Xcode red generated files
if [[ -f "$dest/rules_xcodeproj/generated.xcfilelist" ]]; then
  cd "$BUILD_WORKSPACE_DIRECTORY"

  output_path=$("$bazel_path" info output_path)
  readonly nested_output_base="$output_path/_rules_xcodeproj/build_output_base"

  # Determine bazel-out
  bazelrcs=(
    --noworkspace_rc
    "--bazelrc=$dest/rules_xcodeproj/bazel/xcodeproj.bazelrc"
  )
  if [[ -s ".bazelrc" ]]; then
    bazelrcs+=("--bazelrc=.bazelrc")
  fi

  developer_dir=$(xcode-select -p)
  xcode_build_version=$(/usr/bin/xcodebuild -version | tail -1 | cut -d " " -f3)

  # Re-export `DEVELOPER_DIR` in case a wrapper has wiped it away
  export DEVELOPER_DIR="$developer_dir"

  bazel_out=$("$bazel_path" "${bazelrcs[@]}" \
    --output_base "$nested_output_base" \
    info \
    "--repo_env=DEVELOPER_DIR=$developer_dir" \
    "--repo_env=USE_CLANG_CL=$xcode_build_version" \
    --config=rules_xcodeproj_info \
    output_path)

  # Create directory structure in bazel-out
  cd "$bazel_out"
  sed 's|^\$(BAZEL_OUT)\/\(.*\)\/[^\/]*$|\1|' \
    "$dest/rules_xcodeproj/generated.xcfilelist" \
    | uniq \
    | while IFS= read -r dir
  do
    mkdir -p "$dir"
  done
fi

echo 'Updated project at "%output_path%"'
