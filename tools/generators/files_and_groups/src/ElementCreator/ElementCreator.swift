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

        let createAttributes = CreateAttributes(
            executionRoot: executionRoot,
            externalDir: try environment.externalDir(
                executionRoot: executionRoot
            ),
            workspace: arguments.workspace,
            resolveSymlink: environment.resolveSymlink,
            callable: environment.createAttributesCallable
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
            /*createAttributes:*/ createAttributes,
            /*createSpecialRootGroup:*/ environment.specialRootGroup
        )

        let mainGroup = environment.mainGroup(
            /*rootElements:*/ rootElements,
            /*workspace:*/ arguments.workspace
        )

        let partial = environment.partial(
            elements: allElements,
            mainGroup: mainGroup,
            workspace: arguments.workspace
        )

        return (
            partial: partial,
            knownRegions: knownRegions,
            resolvedRepositories: resolvedRepositories
        )
    }
}
