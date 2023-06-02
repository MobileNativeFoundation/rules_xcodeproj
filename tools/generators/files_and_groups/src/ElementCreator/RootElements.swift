import PBXProj

extension ElementCreator {
    static func rootElements(
        pathTree: PathTreeNode,
        workspace: String,
        createAttributes: CreateAttributes,
        createSpecialRootGroup: Environment.CreateSpecialRootGroup
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
        
        // FIXME: collect child elements

        var rootElements: [Element] = []
        for node in pathTree.children {
            switch node.name {
            case "external":
                rootElements.append(
                    createSpecialRootGroup(
                        /*specialRootGroupType:*/ .legacyBazelExternal,
                        /*childIdentifiers:*/ []
                    )
                )

            case "..":
                rootElements.append(
                    createSpecialRootGroup(
                        /*specialRootGroupType:*/ .siblingBazelExternal,
                        /*childIdentifiers:*/ []
                    )
                )

            case "bazel-out":
                rootElements.append(
                    createSpecialRootGroup(
                        /*specialRootGroupType:*/ .bazelGenerated,
                        /*childIdentifiers:*/ []
                    )
                )

            default:
                break
            }
        }

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
