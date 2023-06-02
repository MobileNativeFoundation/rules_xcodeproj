import PBXProj

extension ElementCreator {
    struct CreateRootElements {
        private let workspace: String
        private let createGroupChild: CreateGroupChild
        private let createGroupChildElements: CreateGroupChildElements
        private let createSpecialRootGroup: CreateSpecialRootGroup

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            workspace: String,
            createGroupChild: CreateGroupChild,
            createGroupChildElements: CreateGroupChildElements,
            createSpecialRootGroup: CreateSpecialRootGroup,
            callable: @escaping Callable
        ) {
            self.workspace = workspace
            self.createGroupChild = createGroupChild
            self.createGroupChildElements = createGroupChildElements
            self.createSpecialRootGroup = createSpecialRootGroup

            self.callable = callable
        }

        func callAsFunction(
            for pathTree: PathTreeNode
        ) -> GroupChildElements {
            return callable(
                /*pathTree:*/ pathTree,
                /*workspace:*/ workspace,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createSpecialRootGroup:*/ createSpecialRootGroup
            )
        }
    }
}

// MARK: - CreateRootElements.Callable

extension ElementCreator.CreateRootElements {
    typealias Callable = (
        _ pathTree: PathTreeNode,
        _ workspace: String,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createSpecialRootGroup: ElementCreator.CreateSpecialRootGroup
    ) -> GroupChildElements

    static func defaultCallable(
        for pathTree: PathTreeNode,
        workspace: String,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createSpecialRootGroup: ElementCreator.CreateSpecialRootGroup
    ) -> GroupChildElements {
        let bazelPath = BazelPath("")

        var groupChildren: [GroupChild] = []
        for node in pathTree.children {
            switch node.name {
            case "external":
                groupChildren.append(
                    .elementAndChildren(
                        createSpecialRootGroup(
                            for: node,
                            specialRootGroupType: .legacyBazelExternal
                        )
                    )
                )

            case "..":
                groupChildren.append(
                    .elementAndChildren(
                        createSpecialRootGroup(
                            for: node,
                            specialRootGroupType: .siblingBazelExternal
                        )
                    )
                )

            case "bazel-out":
                groupChildren.append(
                    .elementAndChildren(
                        createSpecialRootGroup(
                            for: node,
                            specialRootGroupType: .bazelGenerated
                        )
                    )
                )

            default:
                groupChildren.append(
                    createGroupChild(
                        for: node,
                        parentBazelPath: bazelPath,
                        specialRootGroupType: nil
                    )
                )
            }
        }

        return createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren,
            resolvedRepositories:
                [.init(sourcePath: ".", mappedPath: workspace)]
        )
    }
}

struct ResolvedRepository: Equatable {
    let sourcePath: String
    let mappedPath: String
}
