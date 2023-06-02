import PBXProj

extension ElementCreator {
    struct CreateLocalizedFiles {
        private let collectBazelPaths: CollectBazelPaths
        private let createFileElement: CreateFileElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            collectBazelPaths: CollectBazelPaths,
            createFileElement: CreateFileElement,
            callable: @escaping Callable
        ) {
            self.collectBazelPaths = collectBazelPaths
            self.createFileElement = createFileElement

            self.callable = callable
        }

        func callAsFunction(
            for node: PathTreeNode,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            region: String
        ) -> [GroupChild.LocalizedFile] {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*region:*/ region,
                /*collectBazelPaths:*/ collectBazelPaths,
                /*createFileElement:*/ createFileElement
            )
        }
    }
}

// MARK: - CreateLocalizedFiles.Callable

extension ElementCreator.CreateLocalizedFiles {
    typealias Callable = (
        _ node: PathTreeNode,
        _ parentBazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ region: String,
        _ collectBazelPaths: ElementCreator.CollectBazelPaths,
        _ createFileElement: ElementCreator.CreateFileElement
    ) -> [GroupChild.LocalizedFile]

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        region: String,
        collectBazelPaths: ElementCreator.CollectBazelPaths,
        createFileElement: ElementCreator.CreateFileElement
    ) -> [GroupChild.LocalizedFile] {
        let bazelPath = parentBazelPath + node

        let files =  node.children.map { node in
            let childBazelPath = bazelPath + node

            let bazelPaths = collectBazelPaths(
                node: node,
                bazelPath: childBazelPath
            )

            let (basenameWithoutExt, ext) = node.splitExtension()

            let (element, _) = createFileElement(
                name: region,
                ext: ext,
                bazelPath: childBazelPath,
                specialRootGroupType: specialRootGroupType
            )

            return GroupChild.LocalizedFile(
                element: element,
                region: region,
                name: node.name,
                basenameWithoutExt: basenameWithoutExt,
                ext: ext,
                bazelPaths: bazelPaths
            )
        }

        return files
    }
}
