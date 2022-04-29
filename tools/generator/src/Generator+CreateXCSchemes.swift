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
        for (targetID, pbxTarget) in pbxTargets {
            guard let disambiguatedTarget = disambiguatedTargets[targetID] else {
                throw PreconditionError(message: """
                did not find \(targetID) in `disambiguatedTargets`
                """)
            }
            let target = disambiguatedTarget.target

            let buildAction = target.isBuildable ?
                XCScheme.BuildAction(
                    workspaceOutputPath: workspaceOutputPath,
                    pbxTargets: [pbxTarget]
                ) : nil
            let testAction = target.isTestable ?
                XCScheme.TestAction(target: target) : nil

            let launchAction: XCScheme.LaunchAction?
            let profileAction: XCScheme.ProfileAction?
            if target.isLaunchable {
                launchAction = XCScheme.LaunchAction(target: target)
                profileAction = XCScheme.ProfileAction(target: target)
            } else {
                launchAction = nil
                profileAction = nil
            }

            if buildAction == nil, testAction == nil, launchAction == nil,
               profileAction == nil
            {
                continue
            }
            let scheme = XCScheme(
                // TODO(chuck): FIX ME!
                // name: target.name,
                name: "CHUCK \(target.name)",
                lastUpgradeVersion: nil,
                version: nil,
                buildAction: buildAction,
                testAction: testAction,
                launchAction: launchAction,
                profileAction: profileAction,
                analyzeAction: nil,
                archiveAction: nil,
                wasCreatedForAppExtension: nil
            )
            schemes.append(scheme)
        }

        return schemes
    }
}

// MARK: Target Extension

extension Target {
    var isBuildable: Bool {
        return true
    }

    var isTestable: Bool {
        return product.type.isTestBundle
    }

    var isLaunchable: Bool {
        return product.type.isExecutable
    }
}

// MARK: BuildAction Extension

extension XCScheme.BuildAction {
    convenience init(workspaceOutputPath: Path, pbxTargets: [PBXTarget]) {
        let referencedContainer = "container:\(workspaceOutputPath)"
        let entries = pbxTargets.map { pbxTarget in
            XCScheme.BuildAction.Entry(
                buildableReference: .init(
                    referencedContainer: referencedContainer,
                    blueprint: pbxTarget,
                    // TODO(chuck): buildableName should be the filename of the output (e.g.
                    // liblib_impl.a, MyApp.app
                    buildableName: pbxTarget.name,
                    blueprintName: pbxTarget.name
                ),
                buildFor: XCScheme.BuildAction.Entry.BuildFor.default
            )
        }
        self.init(
            buildActionEntries: entries,
            parallelizeBuild: true,
            buildImplicitDependencies: true
        )
    }
}

internal extension XCScheme.TestAction {
    convenience init(target _: Target) {
        // TODO: IMPLEMENT ME!
        self.init(
            buildConfiguration: "", // String,
            macroExpansion: nil, // BuildableReference?
            testables: [], // [TestableReference] = [],
            testPlans: nil, // [TestPlanReference]? = nil,
            preActions: [], // [ExecutionAction] = [],
            postActions: [] // [ExecutionAction] = [],
        )
    }
}

internal extension XCScheme.LaunchAction {
    convenience init(target _: Target) {
        // TODO: IMPLEMENT ME!
        self.init(
            runnable: nil, // Runnable?,
            buildConfiguration: "", // String,
            preActions: [], // [ExecutionAction] = [],
            postActions: [], // [ExecutionAction] = [],
            macroExpansion: nil // BuildableReference? = nil
        )
    }
}

internal extension XCScheme.ProfileAction {
    convenience init(target _: Target) {
        // TODO: IMPLEMENT ME!
        self.init(
            buildableProductRunnable: nil, // BuildableProductRunnable?,
            buildConfiguration: "" // String
            // preActions: [ExecutionAction] = [],
            // postActions: [ExecutionAction] = [],
            // macroExpansion: BuildableReference? = nil,
            // shouldUseLaunchSchemeArgsEnv: Bool = true,
            // savedToolIdentifier: String = "",
            // ignoresPersistentStateOnLaunch: Bool = false,
            // useCustomWorkingDirectory: Bool = false,
            // debugDocumentVersioning: Bool = true,
            // askForAppToLaunch: Bool? = nil,
            // commandlineArguments: CommandLineArguments? = nil,
            // environmentVariables: [EnvironmentVariable]? = nil,
            // enableTestabilityWhenProfilingTests: Bool = true
        )
    }
}

// // MARK: Project Extension

// internal extension Project {
//     var xcodeprojFilename: String {
//         return "\(name).xcodeproj"
//     }

//     var xcodeprojContainerReference: String {
//         return "container:\(xcodeprojFilename)"
//     }
// }
