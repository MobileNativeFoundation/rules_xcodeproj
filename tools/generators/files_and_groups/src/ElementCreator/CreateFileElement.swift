import PBXProj

extension ElementCreator {
    struct CreateFileElement {
        private let createAttributes: CreateAttributes
        private let createIdentifier: CreateIdentifier

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createAttributes: CreateAttributes,
            createIdentifier: CreateIdentifier,
            callable: @escaping Callable
        ) {
            self.createAttributes = createAttributes
            self.createIdentifier = createIdentifier

            self.callable = callable
        }

        /// Creates a `PBXFileReference` element.
        func callAsFunction(
            name: String,
            ext: String?,
            bazelPath: BazelPath,
            specialRootGroupType: SpecialRootGroupType?
        ) -> (
            element: Element,
            resolvedRepository: ResolvedRepository?
        ) {
            return callable(
                /*name:*/ name,
                /*ext:*/ ext,
                /*bazelPath:*/ bazelPath,
                /*specialRootGroupType:*/ specialRootGroupType,
                /*createAttributes:*/ createAttributes,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateFileElement.Callable

extension ElementCreator.CreateFileElement {
    private static let folderTypeFileExtensions: Set<String?> = [
       "bundle",
       "docc",
       "framework",
       "scnassets",
       "xcassets",
       "xcdatamodel",
    ]

    typealias Callable = (
        _ name: String,
        _ ext: String?,
        _ bazelPath: BazelPath,
        _ specialRootGroupType: SpecialRootGroupType?,
        _ createAttributes: ElementCreator.CreateAttributes,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    )

    static func defaultCallable(
        name: String,
        ext: String?,
        bazelPath: BazelPath,
        specialRootGroupType: SpecialRootGroupType?,
        createAttributes: ElementCreator.CreateAttributes,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    ) {
        let lastKnownFileType: String
        let sortOrder: Element.SortOrder
        if bazelPath.isFolder && !folderTypeFileExtensions.contains(ext) {
            lastKnownFileType = "folder"
            sortOrder = .groupLike
        } else {
            lastKnownFileType = ext.flatMap { Xcode.filetype(extension: $0) } ??
                "file"
            sortOrder = .fileLike
        }

        let explicitFileType: String?
        if name == "BUILD" {
            explicitFileType = Xcode.filetype(extension: "bazel")
        } else if name == "Podfile" {
            explicitFileType = Xcode.filetype(extension: "rb")
        } else {
            explicitFileType = nil
        }

        var contentComponents = [
            "{isa = PBXFileReference;",
        ]

        if let explicitFileType {
            contentComponents.append(
                "explicitFileType = \(explicitFileType.pbxProjEscaped);"
            )
        } else {
            contentComponents.append(
                "lastKnownFileType = \(lastKnownFileType.pbxProjEscaped);"
            )
        }

        let attributes = createAttributes(
            name: name,
            bazelPath: bazelPath,
            isGroup: false,
            specialRootGroupType: specialRootGroupType
        )
        if let name = attributes.elementAttributes.name {
            contentComponents.append("name = \(name.pbxProjEscaped);")
        }
        contentComponents.append(
            "path = \(attributes.elementAttributes.path.pbxProjEscaped);"
        )
        contentComponents.append(
            """
sourceTree = \(attributes.elementAttributes.sourceTree.rawValue); }
"""
        )

        return (
            element: .init(
                name: name,
                object: .init(
                    identifier: createIdentifier(
                        path: bazelPath.path,
                        type: .fileReference
                    ),
                    content: contentComponents.joined(separator: " ")
                ),
                sortOrder: sortOrder
            ),
            resolvedRepository: attributes.resolvedRepository
        )
    }
}
