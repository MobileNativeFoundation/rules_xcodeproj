import PathKit
import XcodeProj

extension Generator {
    private static let bazelExec = #"""
env -i \
  DEVELOPER_DIR="$DEVELOPER_DIR" \
  HOME="$HOME" \
  PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  USER="$USER" \
  "$BAZEL_PATH"
"""#

    static func addBazelDependenciesTarget(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String,
        xcodeprojConfiguration: String,
        consolidatedTargets: ConsolidatedTargets
    ) throws -> PBXAggregateTarget? {
        guard
            files.containsExternalFiles || files.containsGeneratedFiles
        else {
            return nil
        }

        let pbxProject = pbxProj.rootObject!

        let projectPlatforms: Set<Platform> = consolidatedTargets.targets.values
            .reduce(into: []) { platforms, consolidatedTarget in
                consolidatedTarget.targets.values
                    .forEach { platforms.insert($0.platform) }
            }

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: [
                "BAZEL_PACKAGE_BIN_DIR": "rules_xcodeproj",
                "INDEX_FORCE_SCRIPT_EXECUTION": true,
                // We have to support only a single platform to prevent issues
                // with duplicated outputs during Index Build, but it also
                // has to be a platform that one of the targets uses, otherwise
                // it's not invoked at all. Index Build is so weird...
                "SUPPORTED_PLATFORMS": projectPlatforms.sorted().first!.name,
                "SUPPORTS_MACCATALYST": true,
                "TARGET_NAME": "BazelDependencies",
            ]
        )
        pbxProj.add(object: debugConfiguration)
        let configurationList = XCConfigurationList(
            buildConfigurations: [debugConfiguration],
            defaultConfigurationName: debugConfiguration.name
        )
        pbxProj.add(object: configurationList)

        let bazelBuildScript = try createBazelBuildScript(
            in: pbxProj,
            buildMode: buildMode,
            files: files,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel,
            xcodeprojConfiguration: xcodeprojConfiguration
        )

        let copyFilesScript = try createCopyFilesScript(
            in: pbxProj,
            files: files,
            filePathResolver: filePathResolver
        )

        let fixModuleMapsScript = try createFixModulemapsScript(
            in: pbxProj,
            files: files,
            filePathResolver: filePathResolver
        )

        let fixInfoPlistsScript = try createFixInfoPlistsScript(
            in: pbxProj,
            files: files,
            filePathResolver: filePathResolver
        )

        let pbxTarget = PBXAggregateTarget(
            name: "BazelDependencies",
            buildConfigurationList: configurationList,
            buildPhases: [
                bazelBuildScript,
                copyFilesScript,
                fixModuleMapsScript,
                fixInfoPlistsScript,
            ].compactMap { $0 },
            productName: "BazelDependencies"
        )
        pbxProj.add(object: pbxTarget)
        pbxProject.targets.append(pbxTarget)

        let attributes: [String: Any] = [
            // TODO: Generate this value
            "CreatedOnToolsVersion": "13.2.1",
        ]
        pbxProject.setTargetAttributes(attributes, target: pbxTarget)

        return pbxTarget
    }

    private static func createBazelBuildScript(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String,
        xcodeprojConfiguration: String
    ) throws -> PBXShellScriptBuildPhase {
        let hasGeneratedFiles = files.containsGeneratedFiles

        var outputFileListPaths: [String] = []
        if files.containsExternalFiles {
            let externalFilesList = try filePathResolver
                .resolve(.internal(externalFileListPath))
                .string
            outputFileListPaths.append(externalFilesList)
        }
        if hasGeneratedFiles {
            let generatedFileList = try filePathResolver
                .resolve(.internal(generatedFileListPath))
                .string
            outputFileListPaths.append(generatedFileList)
        }

        let name: String
        if buildMode.usesBazelModeBuildScripts {
            name = "Bazel Build"
        } else if hasGeneratedFiles {
            name = "Generate Files"
        } else {
            name = "Fetch External Repositories"
        }

        // TODO: Make a `BazelLabel` type and use `.name` here
        let xcodeprojBazelTargetName = String(
            xcodeprojBazelLabel.split(separator: ":")[1]
        )

        let xcodeprojBinDir = calculateBinDir(
            xcodeprojBazelLabel: xcodeprojBazelLabel,
            xcodeprojConfiguration: xcodeprojConfiguration
        )
        let generatedInputsOutputGroup = #"""
generated_inputs \#(xcodeprojConfiguration)
"""#

        let shellScript = [
            bazelSetupCommand(
                buildMode: buildMode,
                generatedInputsOutputGroup: generatedInputsOutputGroup
            ),
            try createGeneratedFileDirectoriesCommand(
                hasGeneratedFiles: hasGeneratedFiles,
                filePathResolver: filePathResolver
            ),
            bazelBuildCommand(
                buildMode: buildMode,
                xcodeprojBazelLabel: xcodeprojBazelLabel,
                xcodeprojBazelTargetName: xcodeprojBazelTargetName,
                xcodeprojBinDir: xcodeprojBinDir
            ),
            try createCheckGeneratedFilesCommand(
                xcodeprojBazelTargetName: xcodeprojBazelTargetName,
                xcodeprojBinDir: xcodeprojBinDir,
                generatedInputsOutputGroup: generatedInputsOutputGroup,
                hasGeneratedFiles: hasGeneratedFiles,
                filePathResolver: filePathResolver
            ),
        ].compactMap { $0 }.joined(separator: "\n")

        let script = PBXShellScriptBuildPhase(
            name: name,
            outputFileListPaths: outputFileListPaths,
            shellPath: "/bin/bash",
            shellScript: shellScript,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        return script
    }

    private static func bazelSetupCommand(
        buildMode: BuildMode,
        generatedInputsOutputGroup: String
    ) -> String {
        let addAdditionalOutputGroups: String
        switch buildMode {
        case .bazel:
            addAdditionalOutputGroups = #"""

# Xcode doesn't adjust `$BUILD_DIR` in scheme action scripts when building for
# previews. So we need to look in the non-preview build directory for this file.
output_groups_file="${BAZEL_BUILD_OUTPUT_GROUPS_FILE/\/Intermediates.noindex\/Previews\/*\/Products\///Products/}"

# We need to read from this file as soon as possible, as concurrent writes to it
# can happen during indexing, which breaks the off-by-one-by-design nature of it
if [ -s "$output_groups_file" ]; then
  while IFS= read -r output_group; do
    output_groups+=("$output_group")
  done < "$output_groups_file"
fi
"""#
        case .xcode:
            addAdditionalOutputGroups = ""
        }

        let lldbInit: String
        if buildMode.requiresLLDBInit {
            lldbInit = #"""

if [[ "$ACTION" != "indexbuild" && "${ENABLE_PREVIEWS:-}" != "YES" ]]; then
  "$BAZEL_INTEGRATION_DIR/create_lldbinit.sh" "$exec_root" > "$BAZEL_LLDB_INIT"
fi

"""#
        } else {
            lldbInit = ""
        }

        return #"""
set -euo pipefail

output_groups=("\#(generatedInputsOutputGroup)")
\#(addAdditionalOutputGroups)
output_groups_flag="--output_groups=$(IFS=, ; echo "${output_groups[*]}")"

if [ "$ACTION" == "indexbuild" ]; then
  # We use a different output base for Index Build to prevent normal builds and
  # indexing waiting on bazel locks from the other
  output_base="$OBJROOT/bazel_output_base"
elif [ "${ENABLE_PREVIEWS:-}" == "YES" ]; then
  # We use a different output base for SwiftUI Previews since they have
  # different swiftcopts, preventing output trashing
  output_base="$OBJROOT/bazel_output_base"
fi

if [[ "${COLOR_DIAGNOSTICS:-NO}" == "YES" ]]; then
  color=yes
else
  color=no
fi

output_path=$(\#(bazelExec) \
  ${output_base:+--output_base "$output_base"} \
  info \
  --color="$color" \
  --experimental_convenience_symlinks=ignore \
  --symlink_prefix=/ \
  output_path)
exec_root="${output_path%/*}"
external="${exec_root%/*/*}/external"
\#(lldbInit)
# We only want to modify `$LINKS_DIR` during normal builds since Indexing can
# run concurrent to normal builds
if [ "$ACTION" != "indexbuild" ]; then
  mkdir -p "$LINKS_DIR"
  cd "$LINKS_DIR"

  # Add BUILD and DONT_FOLLOW_SYMLINKS_WHEN_TRAVERSING_THIS_DIRECTORY_VIA_A_RECURSIVE_TARGET_PATTERN
  # files to the internal links directory to prevent Bazel from recursing into
  # it, and thus following the `external` symlink
  touch BUILD
  touch DONT_FOLLOW_SYMLINKS_WHEN_TRAVERSING_THIS_DIRECTORY_VIA_A_RECURSIVE_TARGET_PATTERN

  # Need to remove the directories that Xcode creates as part of output prep
  rm -rf external
  rm -rf gen_dir

  ln -sf "$external" external
  ln -sf "$BUILD_DIR/bazel-out" gen_dir
fi

cd "$BUILD_DIR"

rm -rf external
rm -rf real-bazel-out

ln -sf "$external" external
ln -sf "$output_path" real-bazel-out
ln -sfn "$PROJECT_DIR" SRCROOT

"""#
    }

    private static func bazelBuildCommand(
        buildMode: BuildMode,
        xcodeprojBazelLabel: String,
        xcodeprojBazelTargetName: String,
        xcodeprojBinDir: String
    ) -> String {
        return #"""
cd "$SRCROOT"

if [ "${ENABLE_PREVIEWS:-}" == "YES" ]; then
  swiftui_previews_flags=(
    --swiftcopt=-Xfrontend
    --swiftcopt=-enable-implicit-dynamic
    --swiftcopt=-Xfrontend
    --swiftcopt=-enable-private-imports
    --swiftcopt=-Xfrontend
    --swiftcopt=-enable-dynamic-replacement-chaining
  )
fi

date +%s > "$INTERNAL_DIR/toplevel_cache_buster"

build_marker="$OBJROOT/bazel_build_start"
touch "$build_marker"

log=$(mktemp)
\#(bazelExec) \
  ${output_base:+--output_base "$output_base"} \
  build \
  --color="$color" \
  --experimental_convenience_symlinks=ignore \
  --symlink_prefix=/ \
  ${swiftui_previews_flags:+${swiftui_previews_flags[*]}} \
  "$output_groups_flag" \
  \#(xcodeprojBazelLabel) \
  2>&1 | tee -i "$log"

for output_group in "${output_groups[@]}"; do
  filelist="\#(xcodeprojBazelTargetName)-${output_group//\//_}"
  filelist="${filelist/#/$output_path/\#(xcodeprojBinDir)/}"
  filelist="${filelist/%/.filelist}"
  if [[ "$filelist" -ot "$build_marker" ]]; then
    echo "error: Bazel didn't generate the correct files (it should have \#
generated outputs for output group \"$output_group\", but the timestamp for \#
\"$filelist\" was from before the build). Please regenerate the project to \#
fix this." >&2
    echo "error: If your bazel version is less than 5.2, you may need to \#
\`bazel clean\` and/or \`bazel shutdown\` to work around a bug in project \#
generation." >&2
    echo "error: If you are still getting this error after all of that, \#
please file a bug report here: \#
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md." \#
>&2
    exit 1
  fi
done

"""#
    }

    private static func createGeneratedFileDirectoriesCommand(
        hasGeneratedFiles: Bool,
        filePathResolver: FilePathResolver
    ) throws -> String? {
        guard hasGeneratedFiles else {
            return nil
        }

        return #"""
# Create parent directories of generated files, so the project navigator works
# better faster

mkdir -p bazel-out
cd bazel-out

sed 's|\/[^\/]*$||' \
  "\#(
  try filePathResolver
      .resolve(.internal(rsyncFileListPath), mode: .script)
      .string
)" \
  | uniq \
  | while IFS= read -r dir
do
  mkdir -p "$dir"
done

"""#
    }

    private static func createCheckGeneratedFilesCommand(
        xcodeprojBazelTargetName: String,
        xcodeprojBinDir: String,
        generatedInputsOutputGroup: String,
        hasGeneratedFiles: Bool,
        filePathResolver: FilePathResolver
    ) throws -> String? {
        guard hasGeneratedFiles else {
            return nil
        }

        let rsynclist = try filePathResolver
            .resolve(.internal(rsyncFileListPath), mode: .script)
        let filelist = #"""
$BAZEL_OUT/\#(xcodeprojBinDir)/\#(xcodeprojBazelTargetName)-\#(generatedInputsOutputGroup).filelist
"""#

        return #"""

diff=$(comm -23 <(sed -e 's|^|bazel-out/|' "\#(rsynclist)" | sort) <(sort "\#(filelist)"))
if ! [ -z "$diff" ]; then
  echo "error: The files that Bazel generated don't match what the project \#
expects. Please regenerate the project." >&2
  echo "error: $diff" >&2
  echo "error: If you still get this error after regenerating your project, \#
please file a bug report here: \#
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md." \#
>&2
  exit 1
fi

"""#
    }

    private static func createCopyFilesScript(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver
    ) throws -> PBXShellScriptBuildPhase? {
        guard files.containsGeneratedFiles else {
            return nil
        }

        let script = PBXShellScriptBuildPhase(
            name: "Copy Files",
            inputFileListPaths: [
                try filePathResolver
                    .resolve(.internal(generatedFileListPath))
                    .string,
            ],
            outputFileListPaths: [
                try filePathResolver
                    .resolve(.internal(copiedGeneratedFileListPath))
                    .string,
            ],
            shellScript: #"""
set -euo pipefail

cd "$BAZEL_OUT"

# Sync to "$BUILD_DIR/bazel-out". This is the same as "$GEN_DIR" for normal
# builds, but is different for Index Builds. `PBXBuildFile`s will use the
# "$GEN_DIR" version, so indexing might get messed up until they are normally
# generated. It's the best we can do though as we need to use the `gen_dir`
# symlink, because Index Build can't modify the normal build's "$BUILD_DIR".
rsync \
  --files-from "\#(
    try filePathResolver
        .resolve(.internal(rsyncFileListPath), mode: .script)
        .string
)" \
  --copy-links \
  --update \
  --chmod=u+w \
  --out-format="%n%L" \
  . \
  "$BUILD_DIR/bazel-out"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createFixModulemapsScript(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver
    ) throws -> PBXShellScriptBuildPhase? {
        guard files.containsModulemaps else {
            return nil
        }

        let script = PBXShellScriptBuildPhase(
            name: "Fix Modulemaps",
            inputFileListPaths: [
                try filePathResolver
                    .resolve(.internal(modulemapsFileListPath))
                    .string,
            ],
            outputFileListPaths: [
                try filePathResolver
                    .resolve(.internal(fixedModulemapsFileListPath))
                    .string,
            ],
            shellScript: #"""
set -euo pipefail

while IFS= read -r input; do
  output="${input%.modulemap}.xcode.modulemap"
  perl -p -e \
    's%^(\s*(\w+ )?header )(?!("\.\.(\/\.\.)*\/|")(bazel-out|external)\/)("(\.\.\/)*)(.*")%\1\6SRCROOT/\8%' \
    < "$input" \
    > "$output"
done < "$SCRIPT_INPUT_FILE_LIST_0"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createFixInfoPlistsScript(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver
    ) throws -> PBXShellScriptBuildPhase? {
        guard files.containsInfoPlists else {
            return nil
        }

        let script = PBXShellScriptBuildPhase(
            name: "Fix Info.plists",
            inputFileListPaths: [
                try filePathResolver
                    .resolve(.internal(infoPlistsFileListPath))
                    .string,
            ],
            outputFileListPaths: [
                try filePathResolver
                    .resolve(.internal(fixedInfoPlistsFileListPath))
                    .string,
            ],
            shellScript: #"""
set -euo pipefail

if [ "$ACTION" == "indexbuild" ]; then
  # Info.plist file paths are `GEN_DIR` based, so this isn't needed during
  # Index Build
  exit
fi

while IFS= read -r input; do
  output="${input%.plist}.xcode.plist"
  cp "$input" "$output"
  plutil -remove UIDeviceFamily "$output" > /dev/null 2>&1 || true
done < "$SCRIPT_INPUT_FILE_LIST_0"

"""#,
            showEnvVarsInLog: false
        )
        pbxProj.add(object: script)

        return script
    }

    private static func calculateBinDir(
        xcodeprojBazelLabel: String,
        xcodeprojConfiguration: String
    ) -> String {
        var packageDirectory = xcodeprojBazelLabel.split(separator: ":")[0]
        packageDirectory = packageDirectory[
            packageDirectory.index(packageDirectory.startIndex, offsetBy: 2)...
        ]

        return (
            Path("\(xcodeprojConfiguration)/bin") + String(packageDirectory)
        ).string
    }
}

private extension Dictionary where Key == FilePath {
    var containsModulemaps: Bool {
        contains(where: { filePath, _ in
            return filePath.type == .generated
                && filePath.path.extension == "modulemap"
        })
    }

    var containsInfoPlists: Bool {
        contains(where: { filePath, _ in
            return filePath.type == .generated
                && filePath.path.lastComponent == "Info.plist"
        })
    }
}
