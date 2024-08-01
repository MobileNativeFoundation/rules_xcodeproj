import PBXProj

extension ElementCreator {
    struct CreateVersionGroup {
        private let createFile: CreateFile
        private let createIdentifier: CreateIdentifier
        private let createVersionGroupElement: CreateVersionGroupElement
        private let collectBazelPaths: CollectBazelPaths
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
            collectBazelPaths: CollectBazelPaths,
            selectedModelVersions: [BazelPath: String],
            callable: @escaping Callable
        ) {
            self.createFile = createFile
            self.createIdentifier = createIdentifier
            self.createVersionGroupElement = createVersionGroupElement
            self.collectBazelPaths = collectBazelPaths
            self.selectedModelVersions = selectedModelVersions

            self.callable = callable
        }

        func callAsFunction(
            name: String,
            nodeChildren: [PathTreeNode],
            parentBazelPath: BazelPath,
            bazelPathType: BazelPathType
        ) -> GroupChild.ElementAndChildren {
            return callable(
                /*name:*/ name,
                /*nodeChildren:*/ nodeChildren,
                /*parentBazelPath:*/ parentBazelPath,
                /*bazelPathType:*/ bazelPathType,
                /*createFile:*/ createFile,
                /*createIdentifier:*/ createIdentifier,
                /*createVersionGroupElement:*/ createVersionGroupElement,
                /*collectBazelPaths:*/ collectBazelPaths,
                /*selectedModelVersions:*/ selectedModelVersions
            )
        }
    }
}

// MARK: - CreateVersionGroup.Callable

extension ElementCreator.CreateVersionGroup {
    typealias Callable = (
        _ name: String,
        _ nodeChildren: [PathTreeNode],
        _ parentBazelPath: BazelPath,
        _ bazelPathType: BazelPathType,
        _ createFile: ElementCreator.CreateFile,
        _ createIdentifier: ElementCreator.CreateIdentifier,
        _ createVersionGroupElement: ElementCreator.CreateVersionGroupElement,
        _ collectBazelPaths: ElementCreator.CollectBazelPaths,
        _ selectedModelVersions: [BazelPath: String]
    ) -> GroupChild.ElementAndChildren

    static func defaultCallable(
        name: String,
        nodeChildren: [PathTreeNode],
        parentBazelPath: BazelPath,
        bazelPathType: BazelPathType,
        createFile: ElementCreator.CreateFile,
        createIdentifier: ElementCreator.CreateIdentifier,
        createVersionGroupElement: ElementCreator.CreateVersionGroupElement,
        collectBazelPaths: ElementCreator.CollectBazelPaths,
        selectedModelVersions: [BazelPath: String]
    ) -> GroupChild.ElementAndChildren {
        let bazelPath = BazelPath(parent: parentBazelPath, path: name)

        let identifier = createIdentifier(
            path: bazelPath.path,
            name: name,
            type: .coreData
        )
        let selectedModelVersion = selectedModelVersions[bazelPath]

        var children: [GroupChild.ElementAndChildren] = []
        var selectedChildIdentifier: String? = nil
        for node in nodeChildren {
            let childName = node.nameForSpecialGroupChild
            let childBazelPath = BazelPath(parent: bazelPath, path: childName)
            
            let transitiveBazelPaths = collectBazelPaths(
                node: node,
                bazelPath: childBazelPath,
                // `createFile` appends to this, so we want this to only be
                // transitive paths
                includeSelf: false
            )

            let result = createFile(
                name: childName,
                isFolder: false,
                bazelPath: childBazelPath,
                bazelPathType: bazelPathType,
                transitiveBazelPaths: transitiveBazelPaths,
                identifierForBazelPaths: identifier
            )
            children.append(result)

            if childName == selectedModelVersion {
                selectedChildIdentifier = result.element.object.identifier
            }
        }

        let (
            group,
            resolvedRepository
        ) = createVersionGroupElement(
            name: name,
            bazelPath: bazelPath,
            bazelPathType: bazelPathType,
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
