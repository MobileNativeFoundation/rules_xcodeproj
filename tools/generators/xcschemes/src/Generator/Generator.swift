import Foundation
import PBXProj
import XCScheme

/// A type that generates and writes to disk `.xcscheme` files for a project.
///
/// The `Generator` type is stateless. It can be used to generate `.xcscheme`
/// files for multiple projects. The `generate()` method is passed all the
/// inputs needed to generate the files.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `.xcscheme` files and writes them to disk.
    func generate(arguments: Arguments) async throws {
        let targets = try await environment.readTargetsFromConsolidationMaps(
            arguments.consolidationMaps,
            referencedContainer: environment.calculateSchemeReferencedContainer(
                installPath: arguments.installPath,
                workspace: arguments.workspace
            )
        )

        let (targetsByKey, targetsByID) = environment.calculateTargetsByKey(
            targets: targets
        )

        let (
            commandLineArguments,
            environmentVariables
        ) = try await environment
            .readTargetArgsAndEnvFile(arguments.targetsArgsEnvFile)
        let extensionHostIDs = arguments.calculateExtensionHostIDs()

        let customSchemeInfos = try await environment.createCustomSchemeInfos(
            commandLineArguments: commandLineArguments,
            customSchemesFile: arguments.customSchemesFile,
            environmentVariables: environmentVariables,
            executionActionsFile: arguments.executionActionsFile,
            extensionHostIDs: extensionHostIDs,
            targetsByID: targetsByID
        )

        let automaticSchemeInfos = try environment.createAutomaticSchemeInfos(
            autogenerationMode: arguments.autogenerationMode,
            commandLineArguments: commandLineArguments,
            customSchemeNames: Set(customSchemeInfos.map(\.name)),
            environmentVariables: environmentVariables,
            extensionHostIDs: extensionHostIDs,
            targets: targets,
            targetsByID: targetsByID,
            targetsByKey: targetsByKey
        )

        // Apply scheme auto-generation exclude patterns
        let schemeInfos = (customSchemeInfos + automaticSchemeInfos).filter { scheme in
            // Scheme name exclude patterns
            let schemeName = scheme.name
            let schemeNameFullRange = NSRange(schemeName.startIndex..., in: schemeName)

            for pattern in arguments.autogenerationSchemeNameExcludePatterns {
                let matches = try? NSRegularExpression(
                    pattern: pattern
                ).matches(in: schemeName, range: schemeNameFullRange)

                if let matches, matches.count > 0 {
                    return false
                }
            }

            return true
        }

        let writeSchemesTask = Task {
            try await environment.writeSchemes(
                defaultXcodeConfiguration:
                    arguments.defaultXcodeConfiguration,
                extensionPointIdentifiers: try environment
                    .readExtensionPointIdentifiersFile(
                        arguments.extensionPointIdentifiersFile
                    ),
                schemeInfos: schemeInfos,
                to: arguments.outputDirectory
            )
        }

        let writeSchemeManagement = Task {
            try await environment.writeSchemeManagement(
                schemeNames: schemeInfos.map(\.name),
                to: arguments.schemeManagementOutputPath
            )
        }

        // Wait for all of the writes to complete
        try await writeSchemeManagement.value
        try await writeSchemesTask.value
    }
}
