import PathKit
import XcodeProj

// DEBUG BEGIN
import Darwin
// DEBUG END

extension Generator {
    /// Creates an array of `XCScheme` entries for the specified targets.
    static func createXCSchemes(
        // TODO(chuck): Should I remove project?
        project _: Project,
        workspaceOutputPath: Path,
        disambiguatedTargets _: [TargetID: DisambiguatedTarget],
        pbxTargets: [TargetID: PBXNativeTarget]
    ) throws -> [XCScheme] {
        // Scheme actions: Build, Test, Run, Profile
        var schemes = [XCScheme]()

        let referencedContainer = "container:\(workspaceOutputPath)"
        for (targetID, pbxTarget) in pbxTargets {
            let buildableReference = pbxTarget.createBuildableReference(
                referencedContainer: referencedContainer
            )
            let buildConfigurationName = pbxTarget
                .buildConfigurationList?.buildConfigurations.first?.name ?? ""

            let buildableProductRunnable: XCScheme.BuildableProductRunnable?
            let buildEntries: [XCScheme.BuildAction.Entry]
            let testables: [XCScheme.TestableReference]
            if pbxTarget.isTestable {
                buildEntries = []
                testables = [.init(
                    skipped: false,
                    // parallelizable: true,
                    buildableReference: buildableReference
                )]
                buildableProductRunnable = nil
            } else {
                buildEntries = [.init(
                    buildableReference: buildableReference,
                    buildFor: [.running, .testing, .profiling, .archiving, .analyzing]
                )]
                testables = []
                buildableProductRunnable = XCScheme.BuildableProductRunnable(buildableReference: buildableReference)
            }

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
            let analyzeAction = XCScheme.AnalyzeAction(buildConfiguration: buildConfigurationName)
            let archiveAction = XCScheme.ArchiveAction(
                buildConfiguration: buildConfigurationName,
                revealArchiveInOrganizer: true
            )

            let scheme = XCScheme(
                // TODO(chuck): FIX ME!
                // name: pbxTarget.name,
                name: "CHUCK \(pbxTarget.name)",
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
            schemes.append(scheme)
        }

        return schemes
    }
}

// MARK: PBXTarget Extension

public extension PBXTarget {
    func createBuildableReference(referencedContainer: String) -> XCScheme.BuildableReference {
        return .init(
            referencedContainer: referencedContainer,
            blueprint: self,
            buildableName: productName ?? name,
            blueprintName: name
        )
    }

    var isTestable: Bool {
        return productType?.isTestBundle ?? false
    }

    var isLaunchable: Bool {
        return productType?.isExecutable ?? false
    }
}
