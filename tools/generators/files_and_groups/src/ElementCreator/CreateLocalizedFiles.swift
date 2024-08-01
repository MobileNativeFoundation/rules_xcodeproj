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
            name: String,
            nodeChildren: [PathTreeNode],
            parentBazelPath: BazelPath,
            region: String
        ) -> [GroupChild.LocalizedFile] {
            return callable(
                /*name:*/ name,
                /*nodeChildren:*/ nodeChildren,
                /*parentBazelPath:*/ parentBazelPath,
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
        _ name: String,
        _ nodeChildren: [PathTreeNode],
        _ parentBazelPath: BazelPath,
        _ region: String,
        _ collectBazelPaths: ElementCreator.CollectBazelPaths,
        _ createLocalizedFileElement: ElementCreator.CreateLocalizedFileElement
    ) -> [GroupChild.LocalizedFile]

    static func defaultCallable(
        name: String,
        nodeChildren: [PathTreeNode],
        parentBazelPath: BazelPath,
        region: String,
        collectBazelPaths: ElementCreator.CollectBazelPaths,
        createLocalizedFileElement: ElementCreator.CreateLocalizedFileElement
    ) -> [GroupChild.LocalizedFile] {
        let bazelPath = BazelPath(parent: parentBazelPath, path: name)
        let lprojPrefix = name

        let files =  nodeChildren.map { node in
            let childName = node.nameForSpecialGroupChild
            let childBazelPath = BazelPath(parent: bazelPath, path: childName)

            let bazelPaths = collectBazelPaths(
                node: node,
                bazelPath: childBazelPath,
                includeSelf: true
            )

            let (basenameWithoutExt, ext) = childName.splitExtension()

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
