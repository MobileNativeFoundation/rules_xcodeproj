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

    static func needsBazelDependenciesTarget(
        buildMode: BuildMode,
        forceBazelDependencies: Bool,
        files: [FilePath: File],
        hasTargets: Bool
    ) -> Bool {
        guard hasTargets else {
            return false
        }

        return (forceBazelDependencies ||
                buildMode.usesBazelModeBuildScripts ||
                files.containsExternalFiles ||
                files.containsGeneratedFiles)
    }

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
        guard needsBazelDependenciesTarget(
            buildMode: buildMode,
            forceBazelDependencies: forceBazelDependencies,
            files: files,
            hasTargets: !consolidatedTargets.targets.isEmpty
        ) else {
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
                // We have to support only a single platform to prevent issues
                // with duplicated outputs during Index Build, but it also
                // has to be a platform that one of the targets uses, otherwise
                // it's not invoked at all. Index Build is so weird...
                "SUPPORTED_PLATFORMS": projectPlatforms.sorted()
                    .first!.variant.rawValue,
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

        let createLLDBSettingsModuleScript =
            try createCreateLLDBSettingsModuleScript(
                in: pbxProj,
                filePathResolver: filePathResolver
            )

        let pbxTarget = PBXAggregateTarget(
            name: "BazelDependencies",
            buildConfigurationList: configurationList,
            buildPhases: [
                bazelBuildScript,
                createLLDBSettingsModuleScript,
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

    private static func createCreateLLDBSettingsModuleScript(
        in pbxProj: PBXProj,
        filePathResolver: FilePathResolver
    ) throws -> PBXShellScriptBuildPhase {
        let script = PBXShellScriptBuildPhase(
            name: "Create swift_debug_settings.py",
            inputPaths: [
                try filePathResolver
                    .resolve(.internal(lldbSwiftSettingsModulePath))
                    .string
            ],
            outputPaths: ["$(OBJROOT)/swift_debug_settings.py"],
            shellScript: #"""
perl -pe 's/\$(\()?([a-zA-Z_]\w*)(?(1)\))/$ENV{$2}/g' \
  "$SCRIPT_INPUT_FILE_0" > "$SCRIPT_OUTPUT_FILE_0"

"""#,
            showEnvVarsInLog: false
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

# Use current path for bazel-out
# This fixes Index Build to use its version of generated files
if [[ "${BAZEL_OUT:0:1}" == '/' ]]; then
    absolute_bazel_out="$BAZEL_OUT"
else
    absolute_bazel_out="$SRCROOT/$BAZEL_OUT"
fi
cat > "$OBJROOT/bazel-out-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [{"external-contents": "$output_path","name": "$absolute_bazel_out","type": "directory-remap"}],"version": 0}
EOF

"""#]

        let indexBuildNoOutputGroups: String
        if buildMode == .xcode {
            indexBuildNoOutputGroups = #"""
    output_groups=("all_generated_inputs")
"""#

            let roots = try targets
                .compactMap { $0.outputs.swift?.generatedHeader }
                .map { filepath -> String in
                    let bazelOut = try filePathResolver.resolve(
                        filepath,
                        useBazelOut: true,
                        mode: .script
                    )
                    let buildDir = try filePathResolver.resolve(
                        filepath,
                        useBazelOut: false,
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
cat > "$OBJROOT/xcode-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [\#(roots)],"version": 0}
EOF

"""#)
        } else {
            indexBuildNoOutputGroups = #"""
    echo "error: Can't yet determine Index Build output group. \#
Next build should succeed. If not, please file a bug report here: \#
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md." >&2
    exit 1
"""#
        }

        return #"""
set -euo pipefail

# In Xcode 14 the "Index" directory was renamed to "Index.noindex".
# `$INDEX_DATA_STORE_DIR` is set to `$OBJROOT/INDEX_DIR/DataStore`, so we can
# use it to determine the name of the directory regardless of Xcode version.
readonly index_dir="${INDEX_DATA_STORE_DIR%/*}"
readonly index_dir_name="${index_dir##*/}"

# Xcode doesn't adjust `$OBJROOT` in scheme action scripts when building for
# previews. So we need to look in the non-preview build directory for this file.
readonly non_preview_objroot="${OBJROOT/\/Intermediates.noindex\/Previews\/*//Intermediates.noindex}"
readonly base_objroot="${non_preview_objroot/\/$index_dir_name\/Build\/Intermediates.noindex//Build/Intermediates.noindex}"
readonly scheme_target_ids_file="$non_preview_objroot/scheme_target_ids"

if [ "$ACTION" == "indexbuild" ]; then
  readonly output_group_prefix=i
else
  readonly output_group_prefix=\#(buildMode.buildOutputGroupPrefix)
fi

# We need to read from `$output_groups_file` as soon as possible, as concurrent
# writes to it can happen during indexing, which breaks the off-by-one-by-design
# nature of it
IFS=$'\n' read -r -d '' -a output_groups < \
  <( "$CALCULATE_OUTPUT_GROUPS_SCRIPT" \
       "$non_preview_objroot" \
       "$base_objroot" \
       "$scheme_target_ids_file" \
       $output_group_prefix \
       && printf '\0' )

if [ -z "${output_groups:-}" ]; then
  if [ "$ACTION" == "indexbuild" ]; then
\#(indexBuildNoOutputGroups)
  else
    echo "error: BazelDependencies invoked without any output groups set. \#
Please file a bug report here: \#
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md." >&2
    exit 1
  fi
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

if [[ "$ACTION" != "indexbuild" && "${ENABLE_PREVIEWS:-}" != "YES" ]]; then
  "$BAZEL_INTEGRATION_DIR/create_lldbinit.sh" "$exec_root" > "$BAZEL_LLDB_INIT"
fi
\#(overlays.joined(separator: "\n"))\#

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
"$BAZEL_INTEGRATION_DIR/process_bazel_build_log.py" \#(bazelExec) \
  ${output_base:+--output_base "$output_base"} \
  build \
  --color="yes" \
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
