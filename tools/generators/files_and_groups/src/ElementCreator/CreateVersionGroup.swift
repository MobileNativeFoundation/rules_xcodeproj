import PBXProj

extension ElementCreator {
    struct CreateVersionGroup {
        private let createFile: CreateFile
        private let createIdentifier: CreateIdentifier
        private let createVersionGroupElement: CreateVersionGroupElement
        private let selectedModelVersions: [BazelPath: BazelPath]

        private let callable: Callable

        /// - Parameters:
        ///   - selectedModelVersions: A `Dictionary` that maps the `BazelPath`
        ///     for an `.xcdatamodeld` group to its selected `.xcdatamodel`
        ///     file.
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createFile: CreateFile,
            createIdentifier: CreateIdentifier,
            createVersionGroupElement: CreateVersionGroupElement,
            selectedModelVersions: [BazelPath: BazelPath],
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
        _ selectedModelVersions: [BazelPath: BazelPath]
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createFile: ElementCreator.CreateFile,
        createIdentifier: ElementCreator.CreateIdentifier,
        createVersionGroupElement: ElementCreator.CreateVersionGroupElement,
        selectedModelVersions: [BazelPath: BazelPath]
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
            let childBazelPath = bazelPath + node
            let result = createFile(
                for: node,
                bazelPath: childBazelPath,
                specialRootGroupType: specialRootGroupType,
                identifierForBazelPaths: identifier
            )
            children.append(result)

            if childBazelPath == selectedModelVersion {
                selectedChildIdentifier = result.element.identifier
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
            childIdentifiers: children.map(\.element.identifier),
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
