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

while (("$#")); do
  case "${1}" in
    "--destination")
      dest="${2}"
      shift 2
      ;;
    "--remove_spaces")
      remove_spaces=true
      shift 1
      ;;
    *)
      fail "Unrecognized argument: ${1}"
      ;;
  esac
done

# Resolve the source
readonly src="$PWD/%source_path%"

# Resolve the destination
[[ -z "${dest:-}" ]] \
  && [[ -n "${BUILD_WORKSPACE_DIRECTORY:-}" ]] \
  && dest="$BUILD_WORKSPACE_DIRECTORY/%output_path%"
[[ -n "${dest:-}" ]] || fail "A destination for the Xcode project was not set"
dest_dir="$(dirname "${dest}")"
[[ -d "${dest_dir}" ]] || \
  fail "The destination directory does not exist or is not a directory" \
    "${dest_dir}"

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

# Remove spaces from filenames if needed
if [[ -n "${remove_spaces:-}" ]]; then
  find "$dest/xcshareddata/xcschemes" \
    -type f \
    -name "* *" \
    -exec bash -c 'mv "$0" "${0// /_}"' {} \;
fi

# Make scripts runnable
if [[ -d "$dest/rules_xcodeproj/bazel" ]]; then
  shopt -s nullglob
  chmod u+x "$dest/rules_xcodeproj/bazel/"*.{py,sh}
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

  # Determine bazel-out
  bazel_out=$(%bazel_path% info output_path 2>/dev/null)
  exec_root="${bazel_out%/*}"
  external="${bazel_out%/*/*}/external"

  # Determine `$BUILD_DIR`
  error_log=$(mktemp)
  exit_status=0
  build_dir=$(\
    xcodebuild -project "$dest" -showBuildSettings 2>&1 | tee -i "$error_log" \
      | grep '\sBUILD_DIR\s=\s' \
      | sed 's/.*= //' \
      || exit_status=$? \
  )
  if [ $exit_status -ne 0 ]; then
    echo "ERROR: Failed to calculate BUILD_DIR for \"$dest\":"
    cat "$error_log" >&2
    exit 1
  fi

  # Create links directory
  mkdir -p "$dest/rules_xcodeproj/links"
  cd "$dest/rules_xcodeproj/links"

  rm -rf external
  rm -rf gen_dir

  ln -sf "$external" external
  ln -sf "$build_dir/bazel-exec-root/bazel-out" gen_dir

  # Create `$GEN_DIR`
  mkdir -p "$build_dir"
  cd "$build_dir"
  rm -f "bazel-exec-root"
  ln -s "$exec_root" "bazel-exec-root"

  # Create directory structure in `$GEN_DIR`
  cd "$bazel_out"
  sed 's|^\$(GEN_DIR)\/\(.*\)\/[^\/]*$|\1|' \
    "$dest/rules_xcodeproj/generated.xcfilelist" \
    | uniq \
    | while IFS= read -r dir
  do
    mkdir -p "$dir"
  done
fi

echo 'Updated project at "%output_path%"'
