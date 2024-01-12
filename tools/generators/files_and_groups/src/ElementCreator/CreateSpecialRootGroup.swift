import AsyncAlgorithms
import PBXProj

extension ElementCreator {
    struct CreateSpecialRootGroup {
        private let createGroupChild: CreateGroupChild
        private let createGroupChildElements: CreateGroupChildElements
        private let createSpecialRootGroupElement: CreateSpecialRootGroupElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createGroupChild: CreateGroupChild,
            createGroupChildElements: CreateGroupChildElements,
            createSpecialRootGroupElement: CreateSpecialRootGroupElement,
            callable: @escaping Callable
        ) {
            self.createGroupChild = createGroupChild
            self.createGroupChildElements = createGroupChildElements
            self.createSpecialRootGroupElement = createSpecialRootGroupElement

            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            specialRootGroupType: SpecialRootGroupType,
            // FIXME: Move to init?
            shardedGroupCreators: [UInt8: ShardedGroupCreator],
            createIdentifier: ElementCreator.CreateIdentifier
        ) async -> GroupChild.ElementAndChildren {
            return await callable(
                /*node:*/ node,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createSpecialRootGroupElement:*/
                          createSpecialRootGroupElement,
                /*createIdentifier:*/ createIdentifier,
                /*shardedGroupCreators:*/ shardedGroupCreators
            )
        }
    }
}

// MARK: - CreateSpecialRootGroup.Callable

extension ElementCreator.CreateSpecialRootGroup {
    typealias Callable = (
        _ node: PathTreeNode,
        _ specialRootGroupType: SpecialRootGroupType,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createSpecialRootGroupElement:
            ElementCreator.CreateSpecialRootGroupElement,
        _ createIdentifier: ElementCreator.CreateIdentifier,
        _ shardedGroupCreators: [UInt8: ShardedGroupCreator]
    ) async -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for node: PathTreeNode,
        specialRootGroupType: SpecialRootGroupType,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createSpecialRootGroupElement:
            ElementCreator.CreateSpecialRootGroupElement,
        createIdentifier: ElementCreator.CreateIdentifier,
        shardedGroupCreators: [UInt8: ShardedGroupCreator]
    ) async -> GroupChild.ElementAndChildren {
        let bazelPath = BazelPath(node.name)

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

        let group = createSpecialRootGroupElement(
            specialRootGroupType: specialRootGroupType,
            childIdentifiers: children.elements.map(\.object.identifier)
        )

        return GroupChild.ElementAndChildren(
            bazelPath: bazelPath,
            element: group,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: nil,
            children: children
        )
    }
}
