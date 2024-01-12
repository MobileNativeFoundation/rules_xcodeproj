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
            for node: PathTreeNode,
            parentBazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?,
            region: String,
            regionNeedsPBXProjEscaping: Bool,
            createIdentifier: ElementCreator.CreateIdentifier
        ) -> [GroupChild.LocalizedFile] {
            return callable(
                /*node:*/ node,
                /*parentBazelPath:*/ parentBazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*region:*/ region,
                /*regionNeedsPBXProjEscaping:*/ regionNeedsPBXProjEscaping,
                /*collectBazelPaths:*/ collectBazelPaths,
                /*createLocalizedFileElement:*/ createLocalizedFileElement,
                /*createIdentifier:*/ createIdentifier
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
        _ regionNeedsPBXProjEscaping: Bool,
        _ collectBazelPaths: ElementCreator.CollectBazelPaths,
        _ createLocalizedFileElement:
            ElementCreator.CreateLocalizedFileElement,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> [GroupChild.LocalizedFile]

    static func defaultCallable(
        for node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        region: String,
        regionNeedsPBXProjEscaping: Bool,
        collectBazelPaths: ElementCreator.CollectBazelPaths,
        createLocalizedFileElement: ElementCreator.CreateLocalizedFileElement,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> [GroupChild.LocalizedFile] {
        let bazelPath = parentBazelPath + node
        let lprojPrefix = node.name
        let lprojPrefixNeedsPBXProjEscaping = node.nameNeedsPBXProjEscaping

        let files =  node.children.map { node in
            let childBazelPath = bazelPath + node

            let bazelPaths = collectBazelPaths(
                node: node,
                bazelPath: childBazelPath
            )

            let (basenameWithoutExt, ext) = node.splitExtension()

            let element = createLocalizedFileElement(
                name: region,
                nameNeedsPBXProjEscaping: regionNeedsPBXProjEscaping,
                path: "\(lprojPrefix)/\(node.name)",
                pathNeedsPBXProjEscaping: lprojPrefixNeedsPBXProjEscaping ||
                    node.nameNeedsPBXProjEscaping,
                ext: ext,
                bazelPath: childBazelPath,
                createIdentifier: createIdentifier
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
