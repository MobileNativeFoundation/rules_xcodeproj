import PBXProj

extension ElementCreator {
    static func rootElements(
        pathTree: PathTreeNode,
        workspace: String,
        createAttributes: Environment.CreateAttributes
    ) -> (
        rootElements: [Element],
        allElements: [Element],
        pathsToIdentifiers: [BazelPath: String],
        knownRegions: Set<String>,
        resolvedRepositories: [ResolvedRepository]
    ) {
        let resolvedRepositories: [ResolvedRepository] = [
            .init(sourcePath: ".", mappedPath: workspace),
        ]

        // FIXME: Implement

        var rootElements: [Element] = []
        for node in pathTree.children {
            switch node.name {
            case "external":
                rootElements.append(
                    ElementCreator.specialRootGroup(
                        specialRootGroupType: .legacyBazelExternal,
                        childIdentifiers: []
                    )
                )

            case "bazel-out":
                rootElements.append(
                    ElementCreator.specialRootGroup(
                        specialRootGroupType: .bazelGenerated,
                        childIdentifiers: []
                    )
                )

            default:
                break
            }
        }

        // FIXME: collect child elements
        let allElements = rootElements

        // Elements are in the correct order, except for `.sortOrder`, so we
        // need to sort on just that.
        rootElements.sort { $0.sortOrder < $1.sortOrder }

        return (
            rootElements: rootElements,
            allElements: allElements,
            pathsToIdentifiers: [:],
            knownRegions: [],
            resolvedRepositories: resolvedRepositories
        )
    }
}

struct ResolvedRepository: Equatable {
    let sourcePath: String
    let mappedPath: String
}
