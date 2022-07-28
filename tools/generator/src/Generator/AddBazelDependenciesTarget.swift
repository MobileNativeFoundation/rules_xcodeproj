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
        forceBazelDependencies: Bool,
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: BazelLabel,
        xcodeprojConfiguration: String,
        consolidatedTargets: ConsolidatedTargets
    ) throws -> PBXAggregateTarget? {
        guard
            !consolidatedTargets.targets.isEmpty &&
            (forceBazelDependencies ||
             buildMode.usesBazelModeBuildScripts ||
             files.containsExternalFiles ||
             files.containsGeneratedFiles)
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
            targets: consolidatedTargets.targets.values
                .flatMap { $0.sortedTargets },
            files: files,
            filePathResolver: filePathResolver,
            xcodeprojBazelLabel: xcodeprojBazelLabel,
            xcodeprojConfiguration: xcodeprojConfiguration
        )

        let pbxTarget = PBXAggregateTarget(
            name: "BazelDependencies",
            buildConfigurationList: configurationList,
            buildPhases: [
                bazelBuildScript,
            ],
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
        targets: [Target],
        files: [FilePath: File],
        filePathResolver: FilePathResolver,
        xcodeprojBazelLabel: BazelLabel,
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

        let xcodeprojBazelTargetName = xcodeprojBazelLabel.name

        let xcodeprojBinDir = calculateBinDir(
            xcodeprojBazelLabel: xcodeprojBazelLabel,
            xcodeprojConfiguration: xcodeprojConfiguration
        )

        let shellScript = [
            try bazelSetupCommand(
                buildMode: buildMode,
                targets: targets,
                filePathResolver: filePathResolver
            ),
            bazelBuildCommand(
                xcodeprojBazelLabel: xcodeprojBazelLabel,
                xcodeprojBazelTargetName: xcodeprojBazelTargetName,
                xcodeprojBinDir: xcodeprojBinDir
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
        targets: [Target],
        filePathResolver: FilePathResolver
    ) throws -> String {
        var overlays: [String] = [#"""

# Use actual paths for Bazel generated files
# This also fixes Index Build to use its version of generated files
cat > "$BUILD_DIR/gen_dir-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [{"external-contents": "$output_path","name": "$GEN_DIR","type": "directory-remap"}],"version": 0}
EOF

"""#]

        if buildMode == .xcode {
            let roots = try targets
                .compactMap { $0.outputs.swift?.generatedHeader }
                .map { filepath -> String in
                    let bazelOut = try filePathResolver.resolve(
                        filepath,
                        useOriginalGeneratedFiles: true,
                        mode: .script
                    )
                    let buildDir = try filePathResolver.resolve(
                        filepath,
                        useOriginalGeneratedFiles: false,
                        mode: .script
                    )
                    return #"""
{"external-contents": "\#(buildDir)","name": "\#(bazelOut)","type": "file"}
"""#
                }
                .joined(separator: ",")

            overlays.append(#"""
# Look up Swift generated headers in `$BUILD_DIR` first, then fall through to \#
`$BAZEL_OUT`
cat > "$BUILD_DIR/xcode-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [\#(roots)],"version": 0}
EOF

"""#)
        }

        return #"""
set -euo pipefail

# Xcode doesn't adjust `$BUILD_DIR` in scheme action scripts when building for
# previews. So we need to look in the non-preview build directory for this file.
output_groups_file="${BAZEL_BUILD_OUTPUT_GROUPS_FILE/\/Intermediates.noindex\/Previews\/*\/Products\///Products/}"

# We need to read from this file as soon as possible, as concurrent writes to it
# can happen during indexing, which breaks the off-by-one-by-design nature of it
output_groups=()
if [ -s "$output_groups_file" ]; then
  while IFS= read -r output_group; do
    output_groups+=("$output_group")
  done < "$output_groups_file"
fi

if [ -z "${output_groups:-}" ]; then
  echo "error: BazelDependencies invoked without any output groups set. \#
Please file a bug report here: \#
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md." >&2
  exit 1
fi
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
  --bes_backend= \
  --bes_results_url= \
  output_path)
exec_root="${output_path%/*}"
external="${exec_root%/*/*}/external"

if [[ "$ACTION" != "indexbuild" && "${ENABLE_PREVIEWS:-}" != "YES" ]]; then
  "$BAZEL_INTEGRATION_DIR/create_lldbinit.sh" "$exec_root" > "$BAZEL_LLDB_INIT"
fi

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
  ln -sf "$BAZEL_OUT" gen_dir
fi
\#(overlays.joined(separator: "\n"))\#

cd "$BUILD_DIR"

rm -rf external
rm -rf bazel-exec-root

ln -sf "$external" external
ln -sf "$exec_root" bazel-exec-root
ln -sfn "$PROJECT_DIR" SRCROOT

"""#
    }

    private static func bazelBuildCommand(
        xcodeprojBazelLabel: BazelLabel,
        xcodeprojBazelTargetName: String,
        xcodeprojBinDir: String
    ) -> String {
        return #"""
cd "$SRCROOT"

if [ "$ACTION" == "indexbuild" ]; then
  index_flags=(
    --bes_backend=
    --bes_results_url=
  )
elif [ "${ENABLE_PREVIEWS:-}" == "YES" ]; then
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
  ${index_flags:+${index_flags[*]}} \
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

    private static func calculateBinDir(
        xcodeprojBazelLabel: BazelLabel,
        xcodeprojConfiguration: String
    ) -> String {
        let packageDirectory = xcodeprojBazelLabel.package

        return (
            Path("\(xcodeprojConfiguration)/bin") + String(packageDirectory)
        ).string
    }
}

private extension Dictionary where Key == FilePath {
    var containsExternalFiles: Bool { keys.containsExternalFiles }
    var containsGeneratedFiles: Bool { keys.containsGeneratedFiles }

    var containsInfoPlists: Bool {
        contains(where: { filePath, _ in
            return filePath.type == .generated
                && filePath.path.lastComponent == "Info.plist"
        })
    }
}

private extension Sequence where Element == FilePath {
    var containsExternalFiles: Bool { contains { $0.type == .external } }
    var containsGeneratedFiles: Bool { contains { $0.type == .generated } }
}
