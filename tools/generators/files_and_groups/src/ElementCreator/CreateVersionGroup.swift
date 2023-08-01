import PBXProj

extension ElementCreator {
    struct CreateVersionGroup {
        private let createFile: CreateFile
        private let createIdentifier: CreateIdentifier
        private let createVersionGroupElement: CreateVersionGroupElement
        private let selectedModelVersions: [BazelPath: String]

        private let callable: Callable

        /// - Parameters:
        ///   - selectedModelVersions: A `Dictionary` that maps the `BazelPath`
        ///     for an `.xcdatamodeld` group to its selected `.xcdatamodel`
        ///     file name.
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createFile: CreateFile,
            createIdentifier: CreateIdentifier,
            createVersionGroupElement: CreateVersionGroupElement,
            selectedModelVersions: [BazelPath: String],
            callable: @escaping Callable
        ) {
            self.createFile = createFile
            self.createIdentifier = createIdentifier
            self.createVersionGroupElement = createVersionGroupElement
            self.selectedModelVersions = selectedModelVersions

            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createFile:*/ createFile,
                /*createIdentifier:*/ createIdentifier,
                /*createVersionGroupElement:*/ createVersionGroupElement,
                /*selectedModelVersions:*/ selectedModelVersions
            )
        }
    }
}

// MARK: - CreateVersionGroup.Callable

extension ElementCreator.CreateVersionGroup {
    typealias Callable = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ createFile: ElementCreator.CreateFile,
        _ createIdentifier: ElementCreator.CreateIdentifier,
        _ createVersionGroupElement: ElementCreator.CreateVersionGroupElement,
        _ selectedModelVersions: [BazelPath: String]
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createFile: ElementCreator.CreateFile,
        createIdentifier: ElementCreator.CreateIdentifier,
        createVersionGroupElement: ElementCreator.CreateVersionGroupElement,
        selectedModelVersions: [BazelPath: String]
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = parentBazelPath + node
        let name = node.name

        let identifier = createIdentifier(
            path: bazelPath.path,
            type: .coreData
        )
        let selectedModelVersion = selectedModelVersions[bazelPath]

        var children: [GroupChild.ElementAndChildren] = []
        var selectedChildIdentifier: String? = nil
        for node in node.children {
            let result = createFile(
                for: node,
                bazelPath: bazelPath + node,
                specialRootGroupType: specialRootGroupType,
                identifierForBazelPaths: identifier
            )
            children.append(result)

            if node.name == selectedModelVersion {
                selectedChildIdentifier = result.element.object.identifier
            }
        }

        let (
            group,
            resolvedRepository
        ) = createVersionGroupElement(
            name: name,
            bazelPath: bazelPath,
            specialRootGroupType: specialRootGroupType,
            identifier: identifier,
            childIdentifiers: children.map(\.element.object.identifier),
            selectedChildIdentifier: selectedChildIdentifier
        )

        return GroupChild.ElementAndChildren(
            bazelPath: bazelPath,
            element: group,
            resolvedRepository: resolvedRepository,
            children: children
        )
    }
}
