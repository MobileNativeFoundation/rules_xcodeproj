import PBXProj

struct ElementCreator {
    private let environment: Environment

    init(environment: Environment) {
        self.environment = environment
    }

    func create(
        pathTree: PathTreeNode,
        arguments: Arguments,
        compileStubNeeded: Bool
    ) throws -> CreatedElements {
        let executionRoot = try environment.readExecutionRootFile(
            arguments.executionRootFile
        )

        let createRootElements = environment.createCreateRootElements(
            executionRoot: executionRoot,
            externalDir: try environment.externalDir(
                executionRoot: executionRoot
            ),
            includeCompileStub: compileStubNeeded,
            installPath: arguments.installPath,
            selectedModelVersions:
                try environment.readSelectedModelVersionsFile(
                    arguments.selectedModelVersionsFile
                ),
            workspace: arguments.workspace
        )
        let rootElements = createRootElements(for: pathTree)

        let mainGroup = environment.createMainGroupContent(
            childIdentifiers: rootElements.elements.map(\.object.identifier),
            workspace: arguments.workspace
        )

        let partial = environment.calculatePartial(
            objects: rootElements.transitiveObjects,
            mainGroup: mainGroup,
            workspace: arguments.workspace
        )

        return CreatedElements(
            partial: partial,
            bazelPathAndIdentifiers: rootElements.bazelPathAndIdentifiers,
            knownRegions: rootElements.knownRegions,
            resolvedRepositories: rootElements.resolvedRepositories
        )
    }
}

struct CreatedElements {
    let partial: String
    let bazelPathAndIdentifiers: [(BazelPath, String)]
    let knownRegions: Set<String>
    let resolvedRepositories: [ResolvedRepository]
}
