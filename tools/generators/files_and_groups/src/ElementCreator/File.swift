import PBXProj

extension ElementCreator {
    private static let folderTypeFileExtensions: Set<String?> = [
       "bundle",
       "docc",
       "framework",
       "scnassets",
       "xcassets",
       "xcdatamodel",
    ]

    /// Creates a `PBXFileReference` element.
    static func file(
        node: PathTreeNode,
        parentBazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createAttributes: Environment.CreateAttributes,
        createIdentifier: Environment.CreateIdentifier
    ) -> (
        element: Element,
        bazelPath: BazelPath,
        resolvedRepository: ResolvedRepository?
    ) {
        let bazelPath = parentBazelPath + node

        var contentComponents = [
            "{isa = PBXFileReference;",
        ]

        let ext = node.extension()

        let lastKnownFileType: String?
        let sortOrder: Element.SortOrder
        if node.isFolder && !folderTypeFileExtensions.contains(ext) {
            lastKnownFileType = "folder"
            sortOrder = .groupLike
        } else {
            lastKnownFileType = ext.flatMap { Xcode.filetype(extension: $0) }
            sortOrder = .fileLike
        }
        if let lastKnownFileType {
            contentComponents.append(
                "lastKnownFileType = \(lastKnownFileType.pbxProjEscaped);"
            )
        }

        let explicitFileType: String?
        if node.name == "BUILD" {
            explicitFileType = Xcode.filetype(extension: "bazel")
        } else if node.name == "Podfile" {
            explicitFileType = Xcode.filetype(extension: "rb")
        } else {
            explicitFileType = nil
        }
        if let explicitFileType {
            contentComponents.append(
                "explicitFileType = \(explicitFileType.pbxProjEscaped);"
            )
        }

        let attributes = createAttributes(
            /*name:*/ node.name,
            /*bazelPath:*/ bazelPath,
            /*isGroup:*/ false,
            /*specialRootGroupType:*/ specialRootGroupType
        )
        if let name = attributes.elementAttributes.name {
            contentComponents.append("name = \(name.pbxProjEscaped);")
        }
        contentComponents.append(
            "path = \(attributes.elementAttributes.path.pbxProjEscaped);"
        )
        contentComponents.append(
            "sourceTree = \(attributes.elementAttributes.sourceTree.rawValue); }"
        )

        return (
            element: .init(
                identifier: createIdentifier(
                    bazelPath.path,
                    /*type:*/ .fileReference
                ),
                content: contentComponents.joined(separator: " "),
                sortOrder: sortOrder
            ),
            bazelPath: bazelPath,
            resolvedRepository: attributes.resolvedRepository
        )
    }
}

private extension PathTreeNode {
    func `extension`() -> String? {
        guard let extIndex = name.lastIndex(of: ".") else {
            return nil
        }
        return String(name[name.index(after: extIndex)..<name.endIndex])
    }
}
