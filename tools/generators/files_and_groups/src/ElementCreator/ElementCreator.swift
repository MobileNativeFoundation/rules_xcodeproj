import PBXProj

struct ElementCreator {
    private let environment: Environment

    init(environment: Environment) {
        self.environment = environment
    }

    func create(
        pathTree: PathTreeNode,
        arguments: Arguments
    ) throws -> (
        partial: String,
        knownRegions: Set<String>,
        resolvedRepositories: [ResolvedRepository]
    ) {
        let executionRoot = try environment.readExecutionRootFile(
            arguments.executionRootFile
        )

        let elementAttributes = environment.attributesWithDependencies(
            executionRoot: executionRoot,
            externalDir: try environment.externalDir(
                /*executionRoot:*/ executionRoot
            ),
            workspace: arguments.workspace,
            resolveSymlink: environment.resolveSymlink
        )

        let (
            rootElements,
            allElements,
            pathsToIdentifiers,
            knownRegions,
            resolvedRepositories
        ) = environment.rootElements(
            /*pathTree:*/ pathTree,
            /*workspace:*/ arguments.workspace,
            /*elementAttributes:*/ elementAttributes
        )

        let mainGroup = environment.mainGroup(
            /*rootElements:*/ rootElements,
            /*workspace:*/ arguments.workspace
        )

        let partial = environment.partial(
            /*elements:*/ allElements,
            /*mainGroup:*/ mainGroup,
            /*workspace:*/ arguments.workspace
        )

        return (
            partial: partial,
            knownRegions: knownRegions,
            resolvedRepositories: resolvedRepositories
        )
    }
}
