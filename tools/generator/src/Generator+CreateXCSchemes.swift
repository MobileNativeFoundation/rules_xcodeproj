import PathKit
import XcodeProj

extension Generator {
    /// Creates an array of `XCScheme` entries for the specified targets.
    static func createXCSchemes(
        filePathResolver: FilePathResolver,
        pbxTargets: [TargetID: PBXTarget]
    ) throws -> [XCScheme] {
        let referencedContainer = filePathResolver.containerReference
        return try pbxTargets.map { $0.1 }.map { pbxTarget in
            try createXCScheme(
                referencedContainer: referencedContainer,
                pbxTarget: pbxTarget
            )
        }
    }

    /// Creates an array of `XCScheme` entries for the specified targets.
    static func createXCScheme(
        referencedContainer: String,
        pbxTarget: PBXTarget
    ) throws -> XCScheme {
        let buildableReference = try pbxTarget.createBuildableReference(
            referencedContainer: referencedContainer
        )
        let buildConfigurationName = pbxTarget.defaultBuildConfigurationName

        let buildEntries: [XCScheme.BuildAction.Entry]
        let testables: [XCScheme.TestableReference]
        if pbxTarget.isTestable {
            buildEntries = []
            testables = [.init(
                skipped: false,
                buildableReference: buildableReference
            )]
        } else {
            buildEntries = [.init(
                buildableReference: buildableReference,
                buildFor: [
                    .running, .testing, .profiling, .archiving,
                    .analyzing,
                ]
            )]
            testables = []
        }
        let buildableProductRunnable: XCScheme.BuildableProductRunnable? =
            pbxTarget.isLaunchable ?
            .init(buildableReference: buildableReference) : nil

        let buildAction = XCScheme.BuildAction(
            buildActionEntries: buildEntries,
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
        let testAction = XCScheme.TestAction(
            buildConfiguration: buildConfigurationName,
            macroExpansion: nil,
            testables: testables
        )
        let launchAction = XCScheme.LaunchAction(
            runnable: buildableProductRunnable,
            buildConfiguration: buildConfigurationName
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

        let scheme = XCScheme(
            name: try pbxTarget.getSchemeName(),
            lastUpgradeVersion: nil,
            version: nil,
            buildAction: buildAction,
            testAction: testAction,
            launchAction: launchAction,
            profileAction: profileAction,
            analyzeAction: analyzeAction,
            archiveAction: archiveAction,
            wasCreatedForAppExtension: nil
        )
        return scheme
    }
}
