import PBXProj

// MARK: - CreateGroup

extension ElementCreator {
    struct CreateGroup {
        private let createGroupElement: CreateGroupElement
        private let createGroupChildElements:
            CreateGroupChildElements

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createGroupChildElements:
                CreateGroupChildElements,
            createGroupElement: CreateGroupElement,
            callable: @escaping Callable
        ) {
            self.createGroupChildElements = createGroupChildElements
            self.createGroupElement = createGroupElement

            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            createGroupChild: CreateGroupChild,
            createIdentifier: ElementCreator.CreateIdentifier
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createGroupElement:*/ createGroupElement,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: CreateGroup.Callable

extension ElementCreator.CreateGroup {
    typealias Callable = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createGroupElement: ElementCreator.CreateGroupElement,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createGroupElement: ElementCreator.CreateGroupElement,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = parentBazelPath + node
        let name = node.name

        let groupChildren = node.children.map { node in
            return createGroupChild(
                for: node,
                parentBazelPath: bazelPath,
                specialRootGroupType: specialRootGroupType,
                createIdentifier: createIdentifier
            )
        }

        let children = createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren,
            createIdentifier: createIdentifier
        )

        let (
            group,
            resolvedRepository
        ) = createGroupElement(
            name: name,
            nameNeedsPBXProjEscaping: node.nameNeedsPBXProjEscaping,
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: children.elements.map(\.object.identifier),
            createIdentifier: createIdentifier
        )

        return GroupChild.ElementAndChildren(
            bazelPath: bazelPath,
            element: group,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: resolvedRepository,
            children: children
        )
    }
}

// MARK: - ConcurrentlyCreateGroup

extension ElementCreator {
    struct ConcurrentlyCreateGroup {
        private let createGroupElement: CreateGroupElement
        private let createGroupChildElements:
            CreateGroupChildElements

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createGroupChildElements:
                CreateGroupChildElements,
            createGroupElement: CreateGroupElement,
            callable: @escaping Callable
        ) {
            self.createGroupChildElements = createGroupChildElements
            self.createGroupElement = createGroupElement

            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            createGroupChild: CreateGroupChild,
            createIdentifier: ElementCreator.CreateIdentifier,
            shardedGroupCreators: [UInt8: ShardedGroupCreator]
        ) async -> GroupChild.ElementAndChildren {
            return await callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createGroupElement:*/ createGroupElement,
                /*createIdentifier:*/ createIdentifier,
                /*shardedGroupCreators:*/ shardedGroupCreators
            )
        }
    }
}

// MARK: ConcurrentlyCreateGroup.Callable

extension ElementCreator.ConcurrentlyCreateGroup {
    typealias Callable = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createGroupElement: ElementCreator.CreateGroupElement,
        _ createIdentifier: ElementCreator.CreateIdentifier,
        _ shardedGroupCreators: [UInt8: ShardedGroupCreator]
    ) async -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createGroupElement: ElementCreator.CreateGroupElement,
        createIdentifier: ElementCreator.CreateIdentifier,
        shardedGroupCreators: [UInt8: ShardedGroupCreator]
    ) async -> GroupChild.ElementAndChildren {
        let bazelPath = parentBazelPath + node
        let name = node.name

        let groupChildren = await withTaskGroup(
            of: GroupChild.self,
            returning: [GroupChild].self
        ) { group in
            for node in node.children {
                let shard = UInt8(abs(node.name.hash % 20))
                let shardedGroupCreator = shardedGroupCreators[shard]!

                group.addTask {
                    return await shardedGroupCreator.createGroupChild(
                        for: node,
                        parentBazelPath: bazelPath,
                        specialRootGroupType: specialRootGroupType
                    )
                }
            }

            // We don't need to sort because `CreateGroupChildElements` will
            // sort for us
            return await Array(group)
        }

        let children = createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren,
            createIdentifier: createIdentifier
        )

        let (
            group,
            resolvedRepository
        ) = createGroupElement(
            name: name,
            nameNeedsPBXProjEscaping: node.nameNeedsPBXProjEscaping,
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: children.elements.map(\.object.identifier),
            createIdentifier: createIdentifier
        )

        return GroupChild.ElementAndChildren(
            bazelPath: bazelPath,
            element: group,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: resolvedRepository,
            children: children
        )
    }
}
