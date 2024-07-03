import PBXProj

extension ElementCreator {
    struct CreateExternalRepositoriesGroup {
        private let createExternalRepositoriesGroupElement:
            CreateExternalRepositoriesGroupElement
        private let createGroupChild: CreateGroupChild
        private let createGroupChildElements: CreateGroupChildElements

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createExternalRepositoriesGroupElement:
                CreateExternalRepositoriesGroupElement,
            createGroupChild: CreateGroupChild,
            createGroupChildElements: CreateGroupChildElements,
            callable: @escaping Callable
        ) {
            self.createExternalRepositoriesGroupElement =
                createExternalRepositoriesGroupElement
            self.createGroupChild = createGroupChild
            self.createGroupChildElements = createGroupChildElements

            self.callable = callable
        }

        func callAsFunction(
            name: String,
            nodeChildren: [PathTreeNode],
            bazelPathType: BazelPathType
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*name:*/ name,
                /*nodeChildren:*/ nodeChildren,
                /*bazelPathType:*/ bazelPathType,
                /*createExternalRepositoriesGroupElement:*/
                    createExternalRepositoriesGroupElement,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements
            )
        }
    }
}

// MARK: - CreateExternalRepositoriesGroup.Callable

extension ElementCreator.CreateExternalRepositoriesGroup {
    typealias Callable = (
        _ name: String,
        _ nodeChildren: [PathTreeNode],
        _ bazelPathType: BazelPathType,
        _ createExternalRepositoriesGroupElement:
            ElementCreator.CreateExternalRepositoriesGroupElement,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        name: String,
        nodeChildren: [PathTreeNode],
        bazelPathType: BazelPathType,
        createExternalRepositoriesGroupElement:
            ElementCreator.CreateExternalRepositoriesGroupElement,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = BazelPath(name)

        let groupChildren = nodeChildren.map { node in
            return createGroupChild(
                for: node,
                parentBazelPath: bazelPath,
                parentBazelPathType: bazelPathType
            )
        }

        let children = createGroupChildElements(
            parentBazelPath: bazelPath,
            groupChildren: groupChildren
        )

        let group = createExternalRepositoriesGroupElement(
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
