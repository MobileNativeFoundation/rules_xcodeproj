import PathKit
import XcodeProj

extension Generator {
    // Xcode likes this list as a string, and apparently in reverse
    private static let allPlatforms = """
watchsimulator \
watchos \
macosx \
iphonesimulator \
iphoneos \
driverkit \
appletvsimulator \
appletvos
"""

    private static let bazelExec = #"""
env -i \
  DEVELOPER_DIR="$DEVELOPER_DIR" \
  HOME="$HOME" \
  PATH="${PATH//\/usr\/local\/bin//opt/homebrew/bin:/usr/local/bin}" \
  USER="$USER" \
  "$BAZEL_PATH"
"""#

    static func addBazelDependenciesTarget(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String
    ) throws -> PBXAggregateTarget? {
        guard
            files.containsExternalFiles || files.containsGeneratedFiles
        else {
            return nil
        }

        let pbxProject = pbxProj.rootObject!

        let debugConfiguration = XCBuildConfiguration(
            name: "Debug",
            buildSettings: [
                "ALLOW_TARGET_PLATFORM_SPECIALIZATION": true,
                "BAZEL_PACKAGE_BIN_DIR": "rules_xcodeproj",
                "INDEX_FORCE_SCRIPT_EXECUTION": true,
                "SUPPORTED_PLATFORMS": allPlatforms,
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
            xcodeprojBazelLabel: xcodeprojBazelLabel
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
        xcodeprojBazelLabel: String
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

        let shellScript = [
            bazelSetupCommand(buildMode: buildMode),
            try createGeneratedFileDirectoriesCommand(
                hasGeneratedFiles: hasGeneratedFiles,
                filePathResolver: filePathResolver
            ),
            bazelBuildCommand(
                buildMode: buildMode,
                xcodeprojBazelLabel: xcodeprojBazelLabel
            ),
        ].compactMap { $0 }.joined(separator: "\n\n")

        let script = PBXShellScriptBuildPhase(
            name: name,
            outputFileListPaths: outputFileListPaths,
            shellScript: shellScript,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        return script
    }

    private static func bazelSetupCommand(
        buildMode: BuildMode
    ) -> String {
        let lldbInit: String
        if buildMode.requiresLLDBInit {
            lldbInit = #"""

if [ "$ACTION" != "indexbuild" ]; then
  "$BAZEL_INTEGRATION_DIR/create_lldbinit.sh" "$exec_root" > "$BAZEL_LLDB_INIT"
fi

"""#
        } else {
            lldbInit = ""
        }

        return #"""
set -euo pipefail

if [ "$ACTION" == "indexbuild" ]; then
  # We use a different output base for Index Build to prevent normal builds and
  # indexing waiting on bazel locks from the other
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
        xcodeprojBazelLabel: String
    ) -> String {
        let createAdditionalOutputGroups: String
        let useAdditionalOutputGroups: String
        switch buildMode {
        case .bazel:
            createAdditionalOutputGroups = #"""

output_groups=()
if [ -s "$BAZEL_BUILD_OUTPUT_GROUPS_FILE" ]; then
  while IFS= read -r output_group; do
    output_groups+=("--output_groups=+$output_group")
  done < "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
fi

"""#
            useAdditionalOutputGroups = #"""
  ${output_groups[@]+"${output_groups[@]}"} \

"""#
        case .xcode:
            createAdditionalOutputGroups = ""
            useAdditionalOutputGroups = ""
        }

        return #"""
cd "$SRCROOT"
\#(createAdditionalOutputGroups)
date +%s > "$INTERNAL_DIR/toplevel_cache_buster"

\#(bazelExec) \
  ${output_base:+--output_base "$output_base"} \
  build \
  --color="$color" \
  --experimental_convenience_symlinks=ignore \
  --output_groups=generated_inputs \
\#(useAdditionalOutputGroups)\#
  \#(xcodeprojBazelLabel)

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
# symlink.
rsync \
  --files-from "\#(
    try filePathResolver
        .resolve(.internal(rsyncFileListPath), mode: .script)
        .string
)" \
  --chmod=u+w \
  -L \
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
