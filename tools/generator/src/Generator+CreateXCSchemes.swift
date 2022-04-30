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
        disambiguatedTargets: [TargetID: DisambiguatedTarget],
        pbxTargets: [TargetID: PBXNativeTarget]
    ) throws -> [XCScheme] {
        // Scheme actions: Build, Test, Run, Profile
        var schemes = [XCScheme]()

        let referencedContainer = "container:\(workspaceOutputPath)"
        for (targetID, pbxTarget) in pbxTargets {
            guard let disambiguatedTarget = disambiguatedTargets[targetID] else {
                throw PreconditionError(message: """
                did not find \(targetID) in `disambiguatedTargets`
                """)
            }
            let target = disambiguatedTarget.target

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

            // DEBUG BEGIN
            fputs("*** CHUCK pbxTarget.name: \(String(reflecting: pbxTarget.name))\n", stderr)
            fputs("*** CHUCK pbxTarget.productName: \(String(reflecting: pbxTarget.productName))\n", stderr)
            fputs("*** CHUCK pbxTarget.product?.name: \(String(reflecting: pbxTarget.product?.name))\n", stderr)
            // DEBUG END

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

// MARK: Target Extension

// extension Target {
//     // var isBuildable: Bool {
//     //     return true
//     // }

//     var isTestable: Bool {
//         return product.type.isTestBundle
//     }

//     var isLaunchable: Bool {
//         return product.type.isExecutable
//     }
// }

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

// MARK: BuildAction Extension

// TODO(chuck): Switch array arguments to Sequence.

// extension XCScheme.BuildAction {
//     convenience init(workspaceOutputPath: Path, pbxTargets: [PBXTarget]) {
//         let referencedContainer = "container:\(workspaceOutputPath)"
//         let entries = pbxTargets.map { pbxTarget in
//             XCScheme.BuildAction.Entry(
//                 buildableReference: .init(
//                     referencedContainer: referencedContainer,
//                     blueprint: pbxTarget,
//                     // TODO(chuck): buildableName should be the filename of the output (e.g.
//                     // liblib_impl.a, MyApp.app
//                     buildableName: pbxTarget.name,
//                     blueprintName: pbxTarget.name
//                 ),
//                 buildFor: XCScheme.BuildAction.Entry.BuildFor.default
//             )
//         }
//         self.init(
//             buildActionEntries: entries,
//             parallelizeBuild: true,
//             buildImplicitDependencies: true
//         )
//     }
// }

// internal extension XCScheme.TestAction {
//     convenience init(pbxTargets: [PBXTarget], buildConfiguration: XCBuildConfiguration) {
//         // DEBUG BEGIN
//         fputs("*** CHUCK TestAction\n", stderr)
//         for pbxTarget in pbxTargets {
//             fputs("*** CHUCK pbxTarget.buildConfigurationList?.buildConfigurations.first?.name: \(String(reflecting: pbxTarget.buildConfigurationList?.buildConfigurations.first?.name))\n", stderr)
//         }
//         // ldRunpathSearchPaths[id] = pbxTarget
//         //     .buildConfigurationList?
//         //     .buildConfigurations
//         //     .first?
//         // DEBUG END

//         // TODO: IMPLEMENT ME!
//         self.init(
//             buildConfiguration: buildConfiguration.name, // String,
//             macroExpansion: nil, // BuildableReference?
//             testables: [], // [TestableReference] = [],
//             testPlans: nil, // [TestPlanReference]? = nil,
//             preActions: [], // [ExecutionAction] = [],
//             postActions: [] // [ExecutionAction] = [],
//         )
//     }
// }

// internal extension XCScheme.LaunchAction {
//     convenience init(target _: Target) {
//         // TODO: IMPLEMENT ME!
//         self.init(
//             runnable: nil, // Runnable?,
//             buildConfiguration: "", // String,
//             preActions: [], // [ExecutionAction] = [],
//             postActions: [], // [ExecutionAction] = [],
//             macroExpansion: nil // BuildableReference? = nil
//         )
//     }
// }

// internal extension XCScheme.ProfileAction {
//     convenience init(target _: Target) {
//         // TODO: IMPLEMENT ME!
//         self.init(
//             buildableProductRunnable: nil, // BuildableProductRunnable?,
//             buildConfiguration: "" // String
//             // preActions: [ExecutionAction] = [],
//             // postActions: [ExecutionAction] = [],
//             // macroExpansion: BuildableReference? = nil,
//             // shouldUseLaunchSchemeArgsEnv: Bool = true,
//             // savedToolIdentifier: String = "",
//             // ignoresPersistentStateOnLaunch: Bool = false,
//             // useCustomWorkingDirectory: Bool = false,
//             // debugDocumentVersioning: Bool = true,
//             // askForAppToLaunch: Bool? = nil,
//             // commandlineArguments: CommandLineArguments? = nil,
//             // environmentVariables: [EnvironmentVariable]? = nil,
//             // enableTestabilityWhenProfilingTests: Bool = true
//         )
//     }
// }

// // MARK: Project Extension

// internal extension Project {
//     var xcodeprojFilename: String {
//         return "\(name).xcodeproj"
//     }

//     var xcodeprojContainerReference: String {
//         return "container:\(xcodeprojFilename)"
//     }
// }
