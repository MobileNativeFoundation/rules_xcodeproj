import PBXProj

extension ElementCreator {
    struct CreateLocalizedFiles {
        private let collectBazelPaths: CollectBazelPaths
        private let createLocalizedFileElement: CreateLocalizedFileElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            collectBazelPaths: CollectBazelPaths,
            createLocalizedFileElement: CreateLocalizedFileElement,
            callable: @escaping Callable
        ) {
            self.collectBazelPaths = collectBazelPaths
            self.createLocalizedFileElement = createLocalizedFileElement

            self.callable = callable
        }

        func callAsFunction(
            for groupNode: PathTreeNode.Group,
            name: String,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            region: String
        ) -> [GroupChild.LocalizedFile] {
            return callable(
                /*groupNode:*/ groupNode,
                /*name:*/ name,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*region:*/ region,
                /*collectBazelPaths:*/ collectBazelPaths,
                /*createLocalizedFileElement:*/ createLocalizedFileElement
            )
        }
    }
}

// MARK: - CreateLocalizedFiles.Callable

extension ElementCreator.CreateLocalizedFiles {
    typealias Callable = (
        _ groupNode: PathTreeNode.Group,
        _ name: String,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ region: String,
        _ collectBazelPaths: ElementCreator.CollectBazelPaths,
        _ createLocalizedFileElement: ElementCreator.CreateLocalizedFileElement
    ) -> [GroupChild.LocalizedFile]

    static func defaultCallable(
        for groupNode: PathTreeNode.Group,
        name: String,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        region: String,
        collectBazelPaths: ElementCreator.CollectBazelPaths,
        createLocalizedFileElement: ElementCreator.CreateLocalizedFileElement
    ) -> [GroupChild.LocalizedFile] {
        let bazelPath = BazelPath(parent: parentBazelPath, path: name)
        let lprojPrefix = name

        let files =  groupNode.children.map { node in
            let childName = node.name
            let childBazelPath = BazelPath(parent: bazelPath, path: childName)

            let bazelPaths = collectBazelPaths(
                node: node,
                bazelPath: childBazelPath,
                includeSelf: true
            )

            let (basenameWithoutExt, ext) = node.splitExtension()

            let element = createLocalizedFileElement(
                name: region,
                path: "\(lprojPrefix)/\(childName)",
                ext: ext,
                bazelPath: childBazelPath
            )

            return GroupChild.LocalizedFile(
                element: element,
                region: region,
                name: childName,
                basenameWithoutExt: basenameWithoutExt,
                ext: ext,
                bazelPaths: bazelPaths
            )
        }

        return files
    }
}
