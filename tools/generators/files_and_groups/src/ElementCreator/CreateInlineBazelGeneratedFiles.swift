import PBXProj

extension ElementCreator {
    struct CreateInlineBazelGeneratedFiles {
        private let createGroupChildElements: CreateGroupChildElements
        private let createInlineBazelGeneratedConfigGroup:
            CreateInlineBazelGeneratedConfigGroup
        private let createInlineBazelGeneratedFilesElement:
            CreateInlineBazelGeneratedFilesElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createGroupChildElements: CreateGroupChildElements,
            createInlineBazelGeneratedConfigGroup:
                CreateInlineBazelGeneratedConfigGroup,
            createInlineBazelGeneratedFilesElement:
                CreateInlineBazelGeneratedFilesElement,
            callable: @escaping Callable
        ) {
            self.createGroupChildElements = createGroupChildElements
            self.createInlineBazelGeneratedConfigGroup =
                createInlineBazelGeneratedConfigGroup
            self.createInlineBazelGeneratedFilesElement =
                createInlineBazelGeneratedFilesElement

            self.callable = callable
        }

        func callAsFunction(
            for generatedFiles: PathTreeNode.GeneratedFiles,
            // Passed in to prevent infinite size
            // (i.e. CreateInlineBazelGeneratedFiles -> CreateGroupChild ->
            // CreateInlineBazelGeneratedFiles)
            createGroupChild: ElementCreator.CreateGroupChild
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*generatedFiles:*/ generatedFiles,
                /*createGroupChild:*/ createGroupChild,
                /*createGroupChildElements:*/ createGroupChildElements,
                /*createInlineBazelGeneratedConfigGroup:*/
                    createInlineBazelGeneratedConfigGroup,
                /*createInlineBazelGeneratedFilesElement:*/
                    createInlineBazelGeneratedFilesElement
            )
        }
    }
}

// MARK: - CreateInlineBazelGeneratedFiles.Callable

extension ElementCreator.CreateInlineBazelGeneratedFiles {
    typealias Callable = (
        _ generatedFiles: PathTreeNode.GeneratedFiles,
        _ createGroupChild: ElementCreator.CreateGroupChild,
        _ createGroupChildElements: ElementCreator.CreateGroupChildElements,
        _ createInlineBazelGeneratedConfigGroup:
            ElementCreator.CreateInlineBazelGeneratedConfigGroup,
        _ createInlineBazelGeneratedFilesElement:
            ElementCreator.CreateInlineBazelGeneratedFilesElement
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for generatedFiles: PathTreeNode.GeneratedFiles,
        createGroupChild: ElementCreator.CreateGroupChild,
        createGroupChildElements: ElementCreator.CreateGroupChildElements,
        createInlineBazelGeneratedConfigGroup:
            ElementCreator.CreateInlineBazelGeneratedConfigGroup,
        createInlineBazelGeneratedFilesElement:
            ElementCreator.CreateInlineBazelGeneratedFilesElement
    ) -> GroupChild.ElementAndChildren {
        let bazelPath: BazelPath
        let children: GroupChildElements
        let path: String

        switch generatedFiles {
        case .singleConfig(let configPath, let configChildren):
            path = "bazel-out/\(configPath)"
            bazelPath = BazelPath(path)

            let groupChildren = configChildren.map { node in
                return createGroupChild(
                    for: node,
                    parentBazelPath: bazelPath,
                    parentBazelPathType: .bazelGenerated
                )
            }

            children = createGroupChildElements(
                parentBazelPath: bazelPath,
                groupChildren: groupChildren
            )

        case .multipleConfigs(let configs):
            path = "bazel-out"
            bazelPath = BazelPath(path)

            let groupChildren = configs.map { config in
                return GroupChild.elementAndChildren(
                    createInlineBazelGeneratedConfigGroup(
                        for: config,
                        parentBazelPath: bazelPath,
                        createGroupChild: createGroupChild
                    )
                )
            }

            children = createGroupChildElements(
                parentBazelPath: bazelPath,
                groupChildren: groupChildren
            )
        }

        let group = createInlineBazelGeneratedFilesElement(
            path: path,
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
