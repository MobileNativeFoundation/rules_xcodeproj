import PathKit
import XcodeProj

extension Generator {
    /// Creates an array of `XCScheme` entries for the specified targets.
    static func createXCSchemes(
        buildMode: BuildMode,
        filePathResolver: FilePathResolver,
        pbxTargets: [TargetID: PBXTarget]
    ) throws -> [XCScheme] {
        let referencedContainer = filePathResolver.containerReference
        return try pbxTargets.map { _, pbxTarget in
            try createXCScheme(
                buildMode: buildMode,
                referencedContainer: referencedContainer,
                pbxTarget: pbxTarget
            )
        }
    }

    // GH399: Derive the defaultLastUpgradeVersion and defaultVersion.
    private static let defaultLastUpgradeVersion = "1320"
    private static let defaultVersion = "1.3"

    /// Creates an `XCScheme` for the specified target.
    private static func createXCScheme(
        buildMode: BuildMode,
        referencedContainer: String,
        pbxTarget: PBXTarget
    ) throws -> XCScheme {
        let buildableReference = try pbxTarget.createBuildableReference(
            referencedContainer: referencedContainer
        )
        let buildConfigurationName = pbxTarget.defaultBuildConfigurationName

        let buildableProductRunnable: XCScheme.BuildableProductRunnable?
        let macroExpansion: XCScheme.BuildableReference?
        let testables: [XCScheme.TestableReference]
        if pbxTarget.isTestable {
            buildableProductRunnable = nil
            macroExpansion = buildableReference
            testables = [.init(
                skipped: false,
                buildableReference: buildableReference
            )]
        } else {
            buildableProductRunnable = pbxTarget.isLaunchable ?
                .init(buildableReference: buildableReference) : nil
            macroExpansion = nil
            testables = []
        }

        let buildAction = XCScheme.BuildAction(
            buildActionEntries: [.init(
                buildableReference: buildableReference,
                buildFor: [
                    .running,
                    .testing,
                    .profiling,
                    .archiving,
                    .analyzing
                ]
            )],
            preActions: createBuildPreActions(
                buildMode: buildMode,
                pbxTarget: pbxTarget,
                buildableReference: buildableReference
            ),
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        let testAction = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: nil,
            testables: testables,
            customLLDBInitFile: buildMode.requiresLLDBInit ?
                "$(BAZEL_LLDB_INIT)" : nil
        )
        let launchAction = XCScheme.LaunchAction(
            runnable: buildableProductRunnable,
            buildConfiguration: buildConfigurationName,
            macroExpansion: macroExpansion,
            customLLDBInitFile: buildMode.requiresLLDBInit ?
                "$(BAZEL_LLDB_INIT)" : nil
        )
        let profileAction = XCScheme.ProfileAction(
            buildableProductRunnable: buildableProductRunnable,
            buildConfiguration: buildConfigurationName
        )
        let analyzeAction = XCScheme.AnalyzeAction(
            buildConfiguration: buildConfigurationName
        )
        let archiveAction = XCScheme.ArchiveAction(
            buildConfiguration: buildConfigurationName,
            revealArchiveInOrganizer: true
        )

        return XCScheme(
            name: pbxTarget.schemeName,
            lastUpgradeVersion: defaultLastUpgradeVersion,
            version: defaultVersion,
            buildAction: buildAction,
            testAction: testAction,
            launchAction: launchAction,
            profileAction: profileAction,
            analyzeAction: analyzeAction,
            archiveAction: archiveAction,
            wasCreatedForAppExtension: nil
        )
    }

    private static func createBuildPreActions(
        buildMode: BuildMode,
        pbxTarget: PBXTarget,
        buildableReference: XCScheme.BuildableReference
    ) -> [XCScheme.ExecutionAction] {
        guard
            buildMode.usesBazelModeBuildScripts && pbxTarget is PBXNativeTarget
        else {
            return []
        }

        return [XCScheme.ExecutionAction(
            scriptText: #"""
mkdir -p "${BAZEL_BUILD_OUTPUT_GROUPS_FILE%/*}"
echo "b $BAZEL_TARGET_ID" > "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"

"""#,
            title: "Set Bazel Build Output Groups",
            environmentBuildable: buildableReference
        )]
    }
}
