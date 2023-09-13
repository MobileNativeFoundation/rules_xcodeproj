import PBXProj

/// A type that generates and writes to disk `.xcscheme` files for a project.
///
/// The `Generator` type is stateless. It can be used to generate multiple
/// partials. The `generate()` method is passed all the inputs needed to
/// generate a partial.
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

        let extensionHostIDs = arguments.calculateExtensionHostIDs()

        let defaultXcodeConfiguration = arguments.defaultXcodeConfiguration

        let extensionPointIdentifiers =
            try environment.readExtensionPointIdentifiersFile(
                arguments.extensionPointIdentifiersFile
            )

        let (targetsByKey, targetsByID) = environment.calculateTargetsByKey(
            targets: targets
        )

        // FIXME: Pull out into function?
        let transitivePreviewReferences = try arguments
            .calculateTransitivePreviewReferences(targetsByID: targetsByID)

        let customSchemeInfos = try environment.createCustomSchemeInfos(
            customSchemeArguments: arguments.customSchemesArguments,
            targetsByID: targetsByID
        )

        let automaticSchemeInfos = try environment
            .createAutomaticSchemeInfos(
                extensionHostIDs: extensionHostIDs,
                targets: targets,
                targetsByID: targetsByID,
                targetsByKey: targetsByKey,
                transitivePreviewReferences: transitivePreviewReferences
            )

        let writeSchemesTask = Task {
            try await environment.writeSchemes(
                defaultXcodeConfiguration: defaultXcodeConfiguration,
                extensionPointIdentifiers: extensionPointIdentifiers,
                schemeInfos: automaticSchemeInfos + customSchemeInfos,
                to: arguments.outputDirectory
            )
        }

        // Wait for all of the writes to complete
        try await writeSchemesTask.value
    }
}
