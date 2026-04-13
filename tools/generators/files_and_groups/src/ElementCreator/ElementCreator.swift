import PBXProj

struct ElementCreator {
    private let environment: Environment

    init(environment: Environment) {
        self.environment = environment
    }

    func create(
        pathTree: [PathTreeNode],
        arguments: Arguments,
        compileStubNeeded: Bool,
        synchronizedFolders: [SynchronizedFolderTarget]
    ) throws -> CreatedElements {
        let executionRoot = try environment.readExecutionRootFile(
            arguments.executionRootFile
        )
        let externalDir = try environment.externalDir(
            executionRoot: executionRoot
        )

        let createRootElements = environment.createCreateRootElements(
            executionRoot: executionRoot,
            externalDir: externalDir,
            includeCompileStub: compileStubNeeded,
            installPath: arguments.installPath,
            selectedModelVersions:
                try environment.readSelectedModelVersionsFile(
                    arguments.selectedModelVersionsFile
                ),
            workspace: arguments.workspace
        )
        let rootElements = createRootElements(for: pathTree)
        let createSynchronizedGroup = environment.createCreateSynchronizedGroup(
            executionRoot: executionRoot,
            externalDir: externalDir,
            installPath: arguments.installPath,
            workspace: arguments.workspace
        )

        let visibleSynchronizedFolderPaths = collectVisibleSynchronizedFolderPaths(
            from: pathTree
        )
        let hiddenSynchronizedGroupObjects = createHiddenSynchronizedGroupObjects(
            synchronizedFolders: synchronizedFolders,
            visibleSynchronizedFolderPaths: visibleSynchronizedFolderPaths,
            createSynchronizedGroup: createSynchronizedGroup
        )

        let mainGroup = environment.createMainGroupContent(
            childIdentifiers: rootElements.elements.map(\.object.identifier),
            indentWidth: arguments.indentWidth,
            tabWidth: arguments.tabWidth,
            usesTabs: arguments.usesTabs,
            workspace: arguments.workspace
        )

        let partial = environment.calculatePartial(
            objects: rootElements.transitiveObjects + hiddenSynchronizedGroupObjects,
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

private func collectVisibleSynchronizedFolderPaths(
    from pathTree: [PathTreeNode]
) -> Set<String> {
    var paths: Set<String> = []

    func collect(_ nodes: [PathTreeNode]) {
        for node in nodes {
            switch node {
            case .file, .generatedFiles:
                continue
            case .group(_, let children):
                collect(children)
            case .synchronizedGroup(_, let synchronizedFolder):
                paths.insert(synchronizedFolder.path.path)
            }
        }
    }

    collect(pathTree)
    return paths
}

private func createHiddenSynchronizedGroupObjects(
    synchronizedFolders: [SynchronizedFolderTarget],
    visibleSynchronizedFolderPaths: Set<String>,
    createSynchronizedGroup: ElementCreator.CreateSynchronizedGroup
) -> [Object] {
    // `PBXNativeTarget.fileSystemSynchronizedGroups` can reference groups that
    // are hidden from the navigator because an ancestor folder was promoted to
    // a visible synchronized root. Emit those objects anyway so every target
    // reference resolves to an object in the pbxproj.
    return groupedSynchronizedFolders(synchronizedFolders)
        .compactMap { synchronizedFolder -> [Object]? in
            guard !visibleSynchronizedFolderPaths.contains(
                synchronizedFolder.path.path
            ) else {
                return nil
            }

            return createSynchronizedGroup(
                name: synchronizedFolderName(for: synchronizedFolder.path),
                synchronizedFolder: synchronizedFolder,
                bazelPathType: .workspace,
                forceWorkspaceRooted: true
            ).transitiveObjects
        }
        .flatMap { $0 }
}

struct CreatedElements {
    let partial: String
    let bazelPathAndIdentifiers: [(BazelPath, String)]
    let knownRegions: Set<String>
    let resolvedRepositories: [ResolvedRepository]
}
