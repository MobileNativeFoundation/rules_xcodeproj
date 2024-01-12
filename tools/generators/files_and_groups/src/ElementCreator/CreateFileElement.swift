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
            lastKnownFileType = ext.flatMap { Xcode.pbxProjEscapedFileType(extension: $0) } ??
                "file"
            sortOrder = .fileLike
        }

        let fileType: String
        let fileTypeType: String
        if name == "BUILD" {
            fileTypeType = "explicitFileType"
            fileType = Xcode.pbxProjEscapedFileType(extension: "bazel")!
        } else if name == "Podfile" {
            fileTypeType = "explicitFileType"
            fileType = Xcode.pbxProjEscapedFileType(extension: "rb")!
        } else {
            fileTypeType = "lastKnownFileType"
            fileType = lastKnownFileType
        }

        let attributes = createAttributes(
            name: name,
            bazelPath: bazelPath,
            isGroup: false,
            specialRootGroupType: specialRootGroupType
        )

        let maybeName: String
        if let name = attributes.elementAttributes.name {
            maybeName = "name = \(name.pbxProjEscaped); "
        } else {
            maybeName = ""
        }

            // TODO: Find a way to have this be escaped ahead of time. If we
            // know that any node name needs to be escaped, we can escape the
            // full path. Should be faster to check each component once.
        let content = """
{isa = PBXFileReference; \
\(fileTypeType) = \(fileType); \
\(maybeName)\
path = \(attributes.elementAttributes.path.pbxProjEscaped); \
sourceTree = \(attributes.elementAttributes.sourceTree.rawValue); }
"""

        return (
            element: .init(
                name: name,
                object: .init(
                    identifier: createIdentifier(
                        path: bazelPath.path,
                        name: attributes.elementAttributes.name ??
                            attributes.elementAttributes.path,
                        type: .fileReference
                    ),
                    content: content
                ),
                sortOrder: sortOrder
            ),
            resolvedRepository: attributes.resolvedRepository
        )
    }
}
