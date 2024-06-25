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
            createSpecialGroupElement: ElementCreator.CreateSpecialRootGroupElement
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createGroupElement:*/ createGroupElement,
                /*createSpecialGroupElement:*/ createSpecialGroupElement
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
        _ createSpecialGroupElement: ElementCreator.CreateSpecialRootGroupElement
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createGroupElement: ElementCreator.CreateGroupElement,
        createSpecialGroupElement: ElementCreator.CreateSpecialRootGroupElement
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = parentBazelPath + node
        let name = node.name

        let groupChildren = node.children.map { node in
            return createGroupChild(
                for: node,
                parentBazelPath: bazelPath,
                specialRootGroupType: specialRootGroupType,
                createSpecialGroupElement: createSpecialGroupElement
            )
        }

        let children = createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren
        )
        
        let group: Element
        var resolvedRepository: ResolvedRepository? = nil
        if node.name.hasPrefix("bazel-out") {
            group = createSpecialGroupElement(
                specialRootGroupType: .bazelGenerated,
                childIdentifiers: children.elements.map(\.object.identifier),
                useRootStableIdentifiers: true,
                bazelPath: bazelPath
            )
        } else {
            (
                group,
                resolvedRepository
            ) = createGroupElement(
                name: name,
                bazelPath: bazelPath,
                specialRootGroupType: specialRootGroupType,
                childIdentifiers: children.elements.map(\.object.identifier)
            )
        }
        
        

        return GroupChild.ElementAndChildren(
            bazelPath: bazelPath,
            element: group,
            includeParentInBazelPathAndIdentifiers: false,
            resolvedRepository: resolvedRepository,
            children: children
        )
    }
}
