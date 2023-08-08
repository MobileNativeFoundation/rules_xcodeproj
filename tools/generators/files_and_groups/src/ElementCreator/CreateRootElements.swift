import PBXProj

extension ElementCreator {
    struct CreateRootElements {
        private let includeCompileStub: Bool
        private let installPath: String
        private let workspace: String
        private let createGroupChild: CreateGroupChild
        private let createGroupChildElements: CreateGroupChildElements
        private let createInternalGroup: CreateInternalGroup
        private let createSpecialRootGroup: CreateSpecialRootGroup

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            includeCompileStub: Bool,
            installPath: String,
            workspace: String,
            createGroupChild: CreateGroupChild,
            createGroupChildElements: CreateGroupChildElements,
            createInternalGroup: CreateInternalGroup,
            createSpecialRootGroup: CreateSpecialRootGroup,
            callable: @escaping Callable
        ) {
            self.includeCompileStub = includeCompileStub
            self.installPath = installPath
            self.workspace = workspace
            self.createGroupChild = createGroupChild
            self.createGroupChildElements = createGroupChildElements
            self.createInternalGroup = createInternalGroup
            self.createSpecialRootGroup = createSpecialRootGroup

            self.callable = callable
        }

        func callAsFunction(
            for pathTree: PathTreeNode
        ) -> GroupChildElements {
            return callable(
                /*pathTree:*/ pathTree,
                /*includeCompileStub:*/ includeCompileStub,
                /*installPath:*/ installPath,
                /*workspace:*/ workspace,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createInternalGroup:*/ createInternalGroup,
                /*createSpecialRootGroup:*/ createSpecialRootGroup
            )
        }
    }
}

// MARK: - CreateRootElements.Callable

extension ElementCreator.CreateRootElements {
    typealias Callable = (
        _ pathTree: PathTreeNode,
        _ includeCompileStub: Bool,
        _ installPath: String,
        _ workspace: String,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createInternalGroup: ElementCreator.CreateInternalGroup,
        _ createSpecialRootGroup: ElementCreator.CreateSpecialRootGroup
    ) -> GroupChildElements

    static func defaultCallable(
        for pathTree: PathTreeNode,
        includeCompileStub: Bool,
        installPath: String,
        workspace: String,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createInternalGroup: ElementCreator.CreateInternalGroup,
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

        if includeCompileStub {
            groupChildren.append(
                createInternalGroup(installPath: installPath)
            )
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
