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

    private static let explicitFileTypeExtensions: Set<String?> = [
        "bazel",
        "bzl",
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
        let impliedExt = ext ?? Xcode.impliedExtension(basename: name)
        let fileTypeType = calculateFileTypeType(basename: name, extension: impliedExt)
        let fileType: String
        let sortOrder: Element.SortOrder
        if bazelPath.isFolder && !folderTypeFileExtensions.contains(ext) {
            fileType = "folder"
            sortOrder = .groupLike
        } else {
            fileType = impliedExt.flatMap(Xcode.pbxProjEscapedFileType) ?? "file"
            sortOrder = .fileLike
        }

        let attributes = createAttributes(
            name: name,
            bazelPath: bazelPath,
            isGroup: false,
            specialRootGroupType: specialRootGroupType
        )

        let nameAttribute: String
        if let name = attributes.elementAttributes.name {
            nameAttribute = "name = \(name.pbxProjEscaped); "
        } else {
            nameAttribute = ""
        }
        let content = """
{isa = PBXFileReference; \
\(fileTypeType) = \(fileType); \
\(nameAttribute)\
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

    private static func calculateFileTypeType(
        basename: String,
        extension: String?
    ) -> String {
        if basename == "Podfile" || explicitFileTypeExtensions.contains(`extension`) {
            return "explicitFileType"
        } else {
            return "lastKnownFileType"
        }
    }
}
