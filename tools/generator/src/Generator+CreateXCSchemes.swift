import Foundation
import PathKit
import XcodeProj

extension Generator {
    /// Creates an array of `XCScheme` entries for the specified targets.
    static func createXCSchemes(
        workspaceOutputPath: Path,
        pbxTargets: [TargetID: PBXNativeTarget]
    ) throws -> [XCScheme] {
        var schemes = [XCScheme]()

        let referencedContainer = "container:\(workspaceOutputPath)"
        for (_, pbxTarget) in pbxTargets {
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
                    buildableReference: buildableReference
                )]
                buildableProductRunnable = nil
            } else {
                buildEntries = [.init(
                    buildableReference: buildableReference,
                    buildFor: [.running, .testing, .profiling, .archiving, .analyzing]
                )]
                testables = []
                buildableProductRunnable = .init(buildableReference: buildableReference)
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
                // name: pbxTarget.schemeName,
                name: "CHUCK \(pbxTarget.schemeName)",
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

// TODO(chuck): Add unit tests.
// TODO(chuck): Move to its own file.

public extension PBXTarget {
    var buildableName: String {
        return productName ?? name
    }

    func createBuildableReference(referencedContainer: String) -> XCScheme.BuildableReference {
        return .init(
            referencedContainer: referencedContainer,
            blueprint: self,
            buildableName: buildableName,
            blueprintName: name
        )
    }

    var schemeName: String {
        // The XcodeProj write logic does not like slashes (/) in the scheme name.
        // It fails to write with a missing folder error.
        return buildableName.replacingOccurrences(
            of: #"[/]"#,
            with: "_",
            options: .regularExpression
        )
    }

    var isTestable: Bool {
        return productType?.isTestBundle ?? false
    }

    var isLaunchable: Bool {
        return productType?.isExecutable ?? false
    }
}
