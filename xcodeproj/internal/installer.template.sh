#!/bin/bash

set -euo pipefail

readonly src="$PWD/%source_path%"
readonly dest="$BUILD_WORKSPACE_DIRECTORY/%output_path%"

# Sync over the project, changing the permissions to be writable

# TODO: Handle schemes schemes
# Don't touch project.xcworkspace as that will make Xcode prompt
rsync \
  --archive \
  --copy-links \
  --chmod=u+w \
  --exclude=project.xcworkspace \
  --exclude=xcuserdata \
  --exclude=xcshareddata/xcschemes \
  --exclude=rules_xcodeproj/links \
  --delete \
  "$src/" "$dest/"

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

# TODO: Uncomment once we create schemes ourselves
# # Prevent Xcode from prompting the user to autocreate schemes for all targets
# plutil -replace IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded -bool false "$workspace_settings"

echo 'Updated project at "%output_path%"'

if [[ \
  (-f "$dest/rules_xcodeproj/external.xcfilelist" && \
   ! -d "$dest/rules_xcodeproj/links/external") || \
  (-f "$dest/rules_xcodeproj/generated.xcfilelist" && \
   ! -d "$dest/rules_xcodeproj/links/gen_dir") \
]]; then
  # If "gen_dir" doesn't exist, this is most likely a fresh project. In that
  # case, we should create generated files to have the initial experience be
  # better.
  echo "Running one time setup..."

  cd "$BUILD_WORKSPACE_DIRECTORY"
  error_log=$(mktemp)
  exit_status=0
  xcodebuild -project "$dest" -scheme "Bazel Dependencies" \
    > "$error_log" 2>&1 \
    || exit_status=$?
  if [ $exit_status -ne 0 ]; then
    echo "WARNING: Failed to build \"Bazel Dependencies\" scheme:"
    cat "$error_log" >&2
  fi
fi
