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

echo 'Updated project at "%output_path%"'

if [[ \
  (-f "$dest/rules_xcodeproj/external.xcfilelist" && \
   ! -d "$dest/rules_xcodeproj/links/external") || \
  (-f "$dest/rules_xcodeproj/generated.copied.xcfilelist" && \
   ! -d "$dest/rules_xcodeproj/links/gen_dir") \
]]; then
  # If "gen_dir" doesn't exist, this is most likely a fresh project. In that
  # case, we should create generated files to have the initial experience be
  # better.
  echo "Running one time setup..."

  cd "$BUILD_WORKSPACE_DIRECTORY"
  error_log=$(mktemp)
  exit_status=0
  xcodebuild -project "$dest" -scheme "BazelDependencies" \
    > "$error_log" 2>&1 \
    || exit_status=$?
  if [ $exit_status -ne 0 ]; then
    echo "WARNING: Failed to build \"BazelDependencies\" scheme:"
    cat "$error_log" >&2
  fi
fi
