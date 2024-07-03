import PBXProj

extension ElementCreator {
    struct CreateInlineBazelGeneratedConfigGroup {
        private let createGroupChildElements:
            CreateGroupChildElements
        private let createInlineBazelGeneratedConfigGroupElement:
        CreateInlineBazelGeneratedConfigGroupElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createGroupChildElements:
                CreateGroupChildElements,
            createInlineBazelGeneratedConfigGroupElement:
                CreateInlineBazelGeneratedConfigGroupElement,
            callable: @escaping Callable
        ) {
            self.createGroupChildElements = createGroupChildElements
            self.createInlineBazelGeneratedConfigGroupElement =
                createInlineBazelGeneratedConfigGroupElement

            self.callable = callable
        }

        func callAsFunction(
            for config: PathTreeNode.GeneratedFiles.Config,
            parentBazelPath: BazelPath,
            // Passed in to prevent infinite size
            // (i.e. CreateGroup -> CreateGroupChild -> CreateGroup)
            createGroupChild: CreateGroupChild
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*config:*/ config,
                /*parentBazelPath:*/ parentBazelPath,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createInlineBazelGeneratedConfigGroupElement:*/
                    createInlineBazelGeneratedConfigGroupElement
            )
        }
    }
}

// MARK: - CreateInlineBazelGeneratedConfigGroup.Callable

extension ElementCreator.CreateInlineBazelGeneratedConfigGroup {
    typealias Callable = (
        _ config: PathTreeNode.GeneratedFiles.Config,
        _ parentBazelPath: BazelPath,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createInlineBazelGeneratedConfigGroupElement:
            ElementCreator.CreateInlineBazelGeneratedConfigGroupElement
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for config: PathTreeNode.GeneratedFiles.Config,
        parentBazelPath: BazelPath,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createInlineBazelGeneratedConfigGroupElement:
            ElementCreator.CreateInlineBazelGeneratedConfigGroupElement
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = BazelPath(parent: parentBazelPath, path: config.path)

        let groupChildren = config.children.map { node in
            return createGroupChild(
                for: node,
                parentBazelPath: bazelPath,
                parentBazelPathType: .bazelGenerated
            )
        }

        let children = createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren
        )

        let group = createInlineBazelGeneratedConfigGroupElement(
            name: config.name,
            path: config.path,
            bazelPath: bazelPath,
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
