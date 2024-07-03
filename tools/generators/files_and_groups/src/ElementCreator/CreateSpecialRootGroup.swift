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
            for groupNode: PathTreeNode.Group,
            name: String,
            specialRootGroupType: SpecialRootGroupType
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*groupNode:*/ groupNode,
                /*name:*/ name,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createSpecialRootGroupElement:*/ createSpecialRootGroupElement
            )
        }
    }
}

// MARK: - CreateSpecialRootGroup.Callable

extension ElementCreator.CreateSpecialRootGroup {
    typealias Callable = (
        _ groupNode: PathTreeNode.Group,
        _ name: String,
        _ specialRootGroupType: SpecialRootGroupType,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createSpecialRootGroupElement:
            ElementCreator.CreateSpecialRootGroupElement
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for groupNode: PathTreeNode.Group,
        name: String,
        specialRootGroupType: SpecialRootGroupType,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createSpecialRootGroupElement:
            ElementCreator.CreateSpecialRootGroupElement
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = BazelPath(name)

        let groupChildren = groupNode.children.map { node in
            return createGroupChild(
                for: node,
                parentBazelPath: bazelPath,
                specialRootGroupType: specialRootGroupType
            )
        }

        let children = createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren
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
