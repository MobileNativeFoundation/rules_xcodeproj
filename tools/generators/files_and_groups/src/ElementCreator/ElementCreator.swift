import Foundation
import PBXProj

struct ElementCreator {
    private let environment: Environment

    init(environment: Environment) {
        self.environment = environment
    }

    func create(
        pathTree: [PathTreeNode],
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
            synchronizedFolders: try readSynchronizedFoldersFile(
                arguments.synchronizedFoldersFile
            ),
            selectedModelVersions:
                try environment.readSelectedModelVersionsFile(
                    arguments.selectedModelVersionsFile
                ),
            workspace: arguments.workspace
        )
        let rootElements = createRootElements(for: pathTree)

        let mainGroup = environment.createMainGroupContent(
            childIdentifiers: rootElements.elements.map(\.object.identifier),
            indentWidth: arguments.indentWidth,
            tabWidth: arguments.tabWidth,
            usesTabs: arguments.usesTabs,
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

/// Reads the paths of synchronized folders, one per line, from `url`.
func readSynchronizedFoldersFile(_ url: URL?) throws -> Set<BazelPath> {
    guard let url else {
        return []
    }
    return Set(
        try String(contentsOf: url, encoding: .utf8)
            .split(separator: "\n")
            .map { BazelPath(String($0)) }
    )
}

/// Removes the paths inside synchronized folders, whose contents Xcode
/// shows on its own.
func removingPathsInSynchronizedFolders(
    _ paths: [BazelPath],
    synchronizedFolders: Set<BazelPath>
) -> [BazelPath] {
    guard !synchronizedFolders.isEmpty else {
        return paths
    }
    return paths.filter { path in
        var components = path.path.split(separator: "/")
        guard !components.isEmpty else {
            return true
        }
        components.removeLast()
        while !components.isEmpty {
            if synchronizedFolders.contains(
                BazelPath(components.joined(separator: "/"))
            ) {
                return false
            }
            components.removeLast()
        }
        return true
    }
}

struct CreatedElements {
    let partial: String
    let bazelPathAndIdentifiers: [(BazelPath, String)]
    let knownRegions: Set<String>
    let resolvedRepositories: [ResolvedRepository]
}
