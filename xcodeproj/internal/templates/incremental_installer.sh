#!/bin/bash

set -euo pipefail

shopt -s nullglob

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
    "--bazel_path")
      bazel_path="${2}"
      shift 2
      ;;
    "--xcodeproj_bazelrc")
      xcodeproj_bazelrc="${2}"
      shift 2
      ;;
    "--destination")
      dest="${2}"
      shift 2
      ;;
    "--execution_root")
      execution_root="${2}"
      shift 2
      ;;
    "--extra_flags_bazelrc")
      extra_flags_bazelrc="${2}"
      shift 2
      ;;
    *)
      fail "Unrecognized argument: ${1}"
      ;;
  esac
done

if [[ -z "${bazel_path:-}" ]]; then
  fail "Missing required argument: --bazel_path"
fi
if [[ -z "${execution_root:-}" ]]; then
  fail "Missing required argument: --execution_root"
fi

# Resolve the inputs
readonly src_generated_xcfilelist="$PWD/%generated_xcfilelist%"
readonly src_generated_directories_filelist="$PWD/%generated_directories_filelist%"
readonly src_project_pbxproj="$PWD/%project_pbxproj%"
readonly src_xcschememanagement="$PWD/%xcschememanagement%"
readonly src_xcschemes="$PWD/%xcschemes%/"
readonly src_xcworkspacedata="$PWD/%contents_xcworkspacedata%"

# Resolve the destination
[[ -z "${dest:-}" ]] \
  && [[ -n "${BUILD_WORKSPACE_DIRECTORY:-}" ]] \
  && dest="$BUILD_WORKSPACE_DIRECTORY/%output_path%"
[[ -n "${dest:-}" ]] || fail "A destination for the Xcode project was not set"
dest_dir="$(dirname "${dest}")"
[[ -d "${dest_dir}" ]] || \
  fail "The destination directory does not exist or is not a directory" \
    "${dest_dir}"

# Copy over `xcschemes`
readonly dest_xcschemes="$dest/xcshareddata/xcschemes"

mkdir -p "$dest_xcschemes"
rsync \
  --archive \
  --chmod=u+w,F-x \
  --delete \
  "$src_xcschemes" "$dest_xcschemes/"

# Resolve the copy command (can't use `cp -c` if the files are on different
# filesystems)
if [[ $(stat -f '%d' "$src_xcschemes") == $(stat -f '%d' "$dest_xcschemes") ]]; then
  readonly cp_cmd="cp -c"
else
  readonly cp_cmd="cp"
fi

# Copy over `project.pbxproj`
readonly dest_project_pbxproj="$dest/project.pbxproj"

$cp_cmd "$src_project_pbxproj" "$dest_project_pbxproj"
chmod +w "$dest_project_pbxproj"

# Copy over bazel integration files
readonly bazel_integration_files=%bazel_integration_files%

mkdir -p "$dest/rules_xcodeproj/bazel"
rm -rf "$dest/rules_xcodeproj/bazel"/*
$cp_cmd "${bazel_integration_files[@]}" "$dest/rules_xcodeproj/bazel"
$cp_cmd "$xcodeproj_bazelrc" "$dest/rules_xcodeproj/bazel/xcodeproj.bazelrc"

if [[ -s "${extra_flags_bazelrc:-}" ]]; then
  $cp_cmd "$extra_flags_bazelrc" "$dest/rules_xcodeproj/bazel/xcodeproj_extra_flags.bazelrc"
else
  rm -f "$dest/rules_xcodeproj/bazel/xcodeproj_extra_flags.bazelrc"
fi

chmod u+w "$dest/rules_xcodeproj/bazel/"*

# Copy over `generated.xcfilelist`
readonly dest_generated_xcfilelist="$dest/rules_xcodeproj/generated.xcfilelist"

$cp_cmd "$src_generated_xcfilelist" "$dest_generated_xcfilelist"
chmod u+w "$dest_generated_xcfilelist"

# - Keep only scripts as runnable
find "$dest/rules_xcodeproj/bazel" \
  -type f \( -name "*.sh" -o -name "*.py" \) \
  -print0 | xargs -0 chmod u+x
find "$dest/rules_xcodeproj/bazel" \
  -type f ! \( -name "swiftc" -o -name "ld" -o -name "libtool" -o -name "import_indexstores" -o -name "*.sh" -o -name "*.py" \) \
  -print0 | xargs -0 chmod -x

# Copy over `project.xcworkspace/contents.xcworkspacedata` if needed
readonly dest_xcworkspacedata="$dest/project.xcworkspace/contents.xcworkspacedata"

if [[ ! -f "$dest_xcworkspacedata" ]] || \
  ! cmp -s "$src_xcworkspacedata" "$dest_xcworkspacedata"
then
  mkdir -p "$dest/project.xcworkspace"
  $cp_cmd "$src_xcworkspacedata" "$dest_xcworkspacedata"
  chmod u+w "$dest_xcworkspacedata"
fi

# Copy over `xcschememanagement.plist`
username="$(/usr/bin/id -un)"
readonly username
readonly user_xcschmes="$dest/xcuserdata/$username.xcuserdatad/xcschemes"
readonly dest_xcschememanagement="$user_xcschmes/xcschememanagement.plist"

mkdir -p "$user_xcschmes"
$cp_cmd "$src_xcschememanagement" "$dest_xcschememanagement"
chmod u+w "$dest_xcschememanagement"

# Set desired `project.xcworkspace` data
readonly workspace_data="$dest/project.xcworkspace/xcshareddata"
readonly workspace_checks="$workspace_data/IDEWorkspaceChecks.plist"
readonly workspace_settings="$workspace_data/WorkspaceSettings.xcsettings"
readonly settings_files=(
  "$workspace_checks"
  "$workspace_settings"
)

mkdir -p "$workspace_data"
for file in "${settings_files[@]}"; do
  if [[ ! -f $file ]]; then
    # Create an empty plist
    echo "{}" | plutil -convert xml1 -o "$file" -
  fi
done

# - Prevent Xcode from doing work that slows down startup
plutil -replace IDEDidComputeMac32BitWarning -bool true "$workspace_checks"

# - Configure the project to use Xcode's new build system.
plutil -remove BuildSystemType "$workspace_settings" > /dev/null || true

# - Prevent Xcode from prompting the user to autocreate schemes for all targets
plutil -replace IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded -bool false "$workspace_settings"

# Create Index Build execution root (`$INDEXING_PROJECT_DIR__YES`)
readonly workspace_name="${execution_root##*/}"
readonly output_base="${execution_root%/*/*}"
readonly indexbuild_exec_root="$output_base/rules_xcodeproj.noindex/indexbuild_output_base/execroot/$workspace_name"

mkdir -p "$indexbuild_exec_root"

# Create folder structure in bazel-out to work around Xcode red generated files
if [[ -s "$src_generated_directories_filelist" ]]; then
  cd "$BUILD_WORKSPACE_DIRECTORY"

  readonly nested_execution_root="$output_base/rules_xcodeproj.noindex/build_output_base/execroot/$workspace_name"

  # Create directory structure in bazel-out
  cd "$nested_execution_root"
  while IFS= read -r dir; do
    mkdir -p "$dir"
  done < "$src_generated_directories_filelist"
fi

echo 'Updated project at "%output_path%"'
