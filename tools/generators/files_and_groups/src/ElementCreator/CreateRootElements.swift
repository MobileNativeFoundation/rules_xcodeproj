import PBXProj

extension ElementCreator {
    class CreateRootElements {
        private let includeCompileStub: Bool
        private let installPath: String
        private let workspace: String
        private let concurrentlyCreateGroupChild: ConcurrentlyCreateGroupChild
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
            concurrentlyCreateGroupChild: ConcurrentlyCreateGroupChild,
            createGroupChild: CreateGroupChild,
            createGroupChildElements: CreateGroupChildElements,
            createInternalGroup: CreateInternalGroup,
            createSpecialRootGroup: CreateSpecialRootGroup,
            callable: @escaping Callable
        ) {
            self.includeCompileStub = includeCompileStub
            self.installPath = installPath
            self.workspace = workspace
            self.concurrentlyCreateGroupChild = concurrentlyCreateGroupChild
            self.createGroupChild = createGroupChild
            self.createGroupChildElements = createGroupChildElements
            self.createInternalGroup = createInternalGroup
            self.createSpecialRootGroup = createSpecialRootGroup

            self.callable = callable
        }

        func callAsFunction(
            for pathTree: PathTreeNode
        ) async -> GroupChildElements {
            return await callable(
                /*pathTree:*/ pathTree,
                /*includeCompileStub:*/ includeCompileStub,
                /*installPath:*/ installPath,
                /*workspace:*/ workspace,
                /*concurrentlyCreateGroupChild:*/ concurrentlyCreateGroupChild,
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
        _ concurrentlyCreateGroupChild:
            ElementCreator.ConcurrentlyCreateGroupChild,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createInternalGroup: ElementCreator.CreateInternalGroup,
        _ createSpecialRootGroup: ElementCreator.CreateSpecialRootGroup
    ) async -> GroupChildElements

    static func defaultCallable(
        for pathTree: PathTreeNode,
        includeCompileStub: Bool,
        installPath: String,
        workspace: String,
        concurrentlyCreateGroupChild:
            ElementCreator.ConcurrentlyCreateGroupChild,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createInternalGroup: ElementCreator.CreateInternalGroup,
        createSpecialRootGroup: ElementCreator.CreateSpecialRootGroup
    ) async -> GroupChildElements {
        let bazelPath = BazelPath("")
        let rootCreateIdentifier =
            ElementCreator.CreateIdentifier(shard: UInt8.max)

        let groupChildren = await withTaskGroup(
            of: GroupChild.self,
            returning: [GroupChild].self
        ) { group in
            // FIXME: Pre-populate with shards
            let shardedGroupCreators: [UInt8: ShardedGroupCreator] = [
                0: ShardedGroupCreator(shard: 0, createGroupChild: createGroupChild),
                1: ShardedGroupCreator(shard: 1, createGroupChild: createGroupChild),
                2: ShardedGroupCreator(shard: 2, createGroupChild: createGroupChild),
                3: ShardedGroupCreator(shard: 3, createGroupChild: createGroupChild),
                4: ShardedGroupCreator(shard: 4, createGroupChild: createGroupChild),
                5: ShardedGroupCreator(shard: 5, createGroupChild: createGroupChild),
                6: ShardedGroupCreator(shard: 6, createGroupChild: createGroupChild),
                7: ShardedGroupCreator(shard: 7, createGroupChild: createGroupChild),
                8: ShardedGroupCreator(shard: 8, createGroupChild: createGroupChild),
                9: ShardedGroupCreator(shard: 9, createGroupChild: createGroupChild),
                10: ShardedGroupCreator(shard: 10, createGroupChild: createGroupChild),
                11: ShardedGroupCreator(shard: 11, createGroupChild: createGroupChild),
                12: ShardedGroupCreator(shard: 12, createGroupChild: createGroupChild),
                13: ShardedGroupCreator(shard: 13, createGroupChild: createGroupChild),
                14: ShardedGroupCreator(shard: 14, createGroupChild: createGroupChild),
                15: ShardedGroupCreator(shard: 15, createGroupChild: createGroupChild),
                16: ShardedGroupCreator(shard: 16, createGroupChild: createGroupChild),
                17: ShardedGroupCreator(shard: 17, createGroupChild: createGroupChild),
                18: ShardedGroupCreator(shard: 18, createGroupChild: createGroupChild),
                19: ShardedGroupCreator(shard: 19, createGroupChild: createGroupChild),
            ]

            for node in pathTree.children {
                group.addTask {
                    switch node.name {
                    case "external":
                        return await .elementAndChildren(
                            createSpecialRootGroup(
                                for: node,
                                specialRootGroupType: .legacyBazelExternal,
                                shardedGroupCreators: shardedGroupCreators,
                                createIdentifier: rootCreateIdentifier
                            )
                        )

                    case "..":
                        return await .elementAndChildren(
                            createSpecialRootGroup(
                                for: node,
                                specialRootGroupType: .siblingBazelExternal,
                                shardedGroupCreators: shardedGroupCreators,
                                createIdentifier: rootCreateIdentifier
                            )
                        )

                    case "bazel-out":
                        return await .elementAndChildren(
                            createSpecialRootGroup(
                                for: node,
                                specialRootGroupType: .bazelGenerated,
                                shardedGroupCreators: shardedGroupCreators,
                                createIdentifier: rootCreateIdentifier
                            )
                        )

                    default:
                        return await concurrentlyCreateGroupChild(
                            for: node,
                            parentBazelPath: bazelPath,
                            specialRootGroupType: nil,
                            createIdentifier: rootCreateIdentifier,
                            shardedGroupCreators: shardedGroupCreators
                        )
                    }
                }
            }

            // We don't need to sort because `CreateGroupChildElements` will
            // sort for us
            var groupChildren = await Array(group)

            if includeCompileStub {
                groupChildren.append(
                    createInternalGroup(installPath: installPath)
                )
            }

            return groupChildren
        }

        return createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren,
            resolvedRepositories:
                [.init(sourcePath: ".", mappedPath: workspace)],
            createIdentifier: rootCreateIdentifier
        )
    }
}

struct ResolvedRepository: Equatable {
    let sourcePath: String
    let mappedPath: String
}

actor ShardedGroupCreator {
    // Each shard has it's own `CreateIdentifier`, which means it has it's own
    // cache. The same groups need to be routed to the same
    // `ShardedGroupCreator` to ensure stable hashes.
    private let createIdentifier: ElementCreator.CreateIdentifier

    private let actualCreateGroupChild: ElementCreator.CreateGroupChild

    init(shard: UInt8, createGroupChild: ElementCreator.CreateGroupChild) {
        self.createIdentifier = ElementCreator.CreateIdentifier(shard: shard)
        self.actualCreateGroupChild = createGroupChild
    }

    func createGroupChild(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?
    ) -> GroupChild {
        return actualCreateGroupChild(
            for: node,
            parentBazelPath: parentBazelPath,
            specialRootGroupType: specialRootGroupType,
            createIdentifier: createIdentifier
        )
    }
}
