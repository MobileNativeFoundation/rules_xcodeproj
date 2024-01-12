import PBXProj

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

// MARK: - CreateGroup.Callable

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
