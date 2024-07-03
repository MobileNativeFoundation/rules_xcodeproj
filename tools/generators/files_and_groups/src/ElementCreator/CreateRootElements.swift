import PBXProj

extension ElementCreator {
    struct CreateRootElements {
        private let includeCompileStub: Bool
        private let installPath: String
        private let workspace: String
        private let createExternalRepositoriesGroup: CreateExternalRepositoriesGroup
        private let createGroupChild: CreateGroupChild
        private let createGroupChildElements: CreateGroupChildElements
        private let createInternalGroup: CreateInternalGroup

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            includeCompileStub: Bool,
            installPath: String,
            workspace: String,
            createExternalRepositoriesGroup: CreateExternalRepositoriesGroup,
            createGroupChild: CreateGroupChild,
            createGroupChildElements: CreateGroupChildElements,
            createInternalGroup: CreateInternalGroup,
            callable: @escaping Callable
        ) {
            self.includeCompileStub = includeCompileStub
            self.installPath = installPath
            self.workspace = workspace
            self.createExternalRepositoriesGroup =
                createExternalRepositoriesGroup
            self.createGroupChild = createGroupChild
            self.createGroupChildElements = createGroupChildElements
            self.createInternalGroup = createInternalGroup

            self.callable = callable
        }

        func callAsFunction(
            for pathTree: [PathTreeNode]
        ) -> GroupChildElements {
            return callable(
                /*pathTree:*/ pathTree,
                /*includeCompileStub:*/ includeCompileStub,
                /*installPath:*/ installPath,
                /*workspace:*/ workspace,
                /*createExternalRepositoriesGroup:*/
                    createExternalRepositoriesGroup,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createInternalGroup:*/ createInternalGroup
            )
        }
    }
}

// MARK: - CreateRootElements.Callable

extension ElementCreator.CreateRootElements {
    typealias Callable = (
        _ pathTree: [PathTreeNode],
        _ includeCompileStub: Bool,
        _ installPath: String,
        _ workspace: String,
        _ createExternalRepositoriesGroup:
            ElementCreator.CreateExternalRepositoriesGroup,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createInternalGroup: ElementCreator.CreateInternalGroup
    ) -> GroupChildElements

    static func defaultCallable(
        for pathTree: [PathTreeNode],
        includeCompileStub: Bool,
        installPath: String,
        workspace: String,
        createExternalRepositoriesGroup:
            ElementCreator.CreateExternalRepositoriesGroup,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createInternalGroup: ElementCreator.CreateInternalGroup
    ) -> GroupChildElements {
        let bazelPath = BazelPath("")

        var groupChildren: [GroupChild] = []
        for node in pathTree {
            switch node {
            case .group(let name, let children):
                switch name {
                case "external":
                    groupChildren.append(
                        .elementAndChildren(
                            createExternalRepositoriesGroup(
                                name: name,
                                nodeChildren: children,
                                bazelPathType: .legacyBazelExternal
                            )
                        )
                    )

                case "..":
                    groupChildren.append(
                        .elementAndChildren(
                            createExternalRepositoriesGroup(
                                name: name,
                                nodeChildren: children,
                                bazelPathType: .siblingBazelExternal
                            )
                        )
                    )

                default:
                    groupChildren.append(
                        createGroupChild(
                            for: node,
                            parentBazelPath: bazelPath,
                            parentBazelPathType: .workspace
                        )
                    )
                }

            case .file, .generatedFiles:
                groupChildren.append(
                    createGroupChild(
                        for: node,
                        parentBazelPath: bazelPath,
                        parentBazelPathType: .workspace
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
