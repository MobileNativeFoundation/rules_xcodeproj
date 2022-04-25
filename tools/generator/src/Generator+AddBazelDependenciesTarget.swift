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

    private static let setup = #"""
if [ "$ACTION" == "indexbuild" ]; then
  # We use a different output base for Index Build to prevent normal builds and
  # indexing waiting on bazel locks from the other
  output_base="$OBJROOT/bazel_output_base"
fi

output_path=$(\#(bazelExec) \
  ${output_base:+--output_base "$output_base"} \
  info \
  --experimental_convenience_symlinks=ignore \
  output_path)
external="${output_path%/*/*/*}/external"

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

    static func addBazelDependenciesTarget(
        in pbxProj: PBXProj,
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

        let fetchExternalReposScript = try createFetchExternalReposScript(
            in: pbxProj,
            files: files,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel
        )

        let generateFilesScript = try createGenerateFilesScript(
            in: pbxProj,
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
            name: "Bazel Dependencies",
            buildConfigurationList: configurationList,
            buildPhases: [
                fetchExternalReposScript,
                generateFilesScript,
                copyFilesScript,
                fixModuleMapsScript,
                fixInfoPlistsScript,
            ].compactMap { $0 },
            productName: "Bazel Dependencies"
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

    private static func createFetchExternalReposScript(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String
    ) throws -> PBXShellScriptBuildPhase? {
        guard !files.containsGeneratedFiles else {
            return nil
        }

        let script = PBXShellScriptBuildPhase(
            name: "Fetch External Repositories",
            outputFileListPaths: [
                try filePathResolver
                    .resolve(.internal(externalFileListPath))
                    .string,
            ],
            shellScript: #"""
set -eu

\#(setup)

cd "$SRCROOT"

\#(bazelExec) \
  ${output_base:+--output_base "$output_base"} \
  build \
  --nobuild \
  --experimental_convenience_symlinks=ignore \
  \#(xcodeprojBazelLabel)

"""#,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        return script
    }

    private static func createGenerateFilesScript(
        in pbxProj: PBXProj,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: String
    ) throws -> PBXShellScriptBuildPhase? {
        guard files.containsGeneratedFiles else {
            return nil
        }

        let generatedFileList = try filePathResolver
            .resolve(.internal(generatedFileListPath))
            .string

        let outputFileListPaths: [String]
        if files.containsExternalFiles {
            outputFileListPaths = [
                try filePathResolver
                    .resolve(.internal(externalFileListPath))
                    .string,
                generatedFileList,
            ]
        } else {
            outputFileListPaths = [generatedFileList]
        }

        let script = PBXShellScriptBuildPhase(
            name: "Generate Files",
            outputFileListPaths: outputFileListPaths,
            shellScript: #"""
set -eu

\#(setup)

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

cd "$SRCROOT"

date +%s > "$INTERNAL_DIR/toplevel_cache_buster"

\#(bazelExec) \
  ${output_base:+--output_base "$output_base"} \
  build \
  --experimental_convenience_symlinks=ignore \
  --output_groups=generated_inputs \
  \#(xcodeprojBazelLabel)

"""#,
            showEnvVarsInLog: false,
            alwaysOutOfDate: true
        )
        pbxProj.add(object: script)

        return script
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
set -eu

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
set -eu

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
set -eu

while IFS= read -r input; do
  output="${input%.plist}.xcode.plist"
  cp "$input" "$output"
  plutil -remove UIDeviceFamily "$output" || true
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
