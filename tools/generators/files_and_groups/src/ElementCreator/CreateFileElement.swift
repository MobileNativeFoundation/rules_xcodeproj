import PBXProj

extension ElementCreator {
    struct CreateFileElement {
        private let createAttributes: CreateAttributes
        private let createIdentifier: CreateIdentifier
        private let synchronizedFolders: Set<BazelPath>

        private let callable: Callable

        /// - Parameters:
        ///   - synchronizedFolders: The paths of folders to create as
        ///     `PBXFileSystemSynchronizedRootGroup`s.
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createAttributes: CreateAttributes,
            createIdentifier: CreateIdentifier,
            synchronizedFolders: Set<BazelPath> = [],
            callable: @escaping Callable
        ) {
            self.createAttributes = createAttributes
            self.createIdentifier = createIdentifier
            self.synchronizedFolders = synchronizedFolders

            self.callable = callable
        }

        /// Creates a `PBXFileReference` element, or a
        /// `PBXFileSystemSynchronizedRootGroup` element for a synchronized
        /// folder.
        func callAsFunction(
            name: String,
            ext: String?,
            bazelPath: BazelPath,
            bazelPathType: BazelPathType
        ) -> (
            element: Element,
            resolvedRepository: ResolvedRepository?
        ) {
            if synchronizedFolders.contains(bazelPath) {
                return Self.synchronizedRootGroup(
                    name: name,
                    bazelPath: bazelPath,
                    bazelPathType: bazelPathType,
                    createAttributes: createAttributes
                )
            }

            return callable(
                /*name:*/ name,
                /*ext:*/ ext,
                /*bazelPath:*/ bazelPath,
                /*bazelPathType:*/ bazelPathType,
                /*createAttributes:*/ createAttributes,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateFileElement.Callable

extension ElementCreator.CreateFileElement {
    private static let explicitFileTypeExtensions: Set<String?> = [
        "bazel",
        "bzl",
        "podspec",
    ]

    typealias Callable = (
        _ name: String,
        _ ext: String?,
        _ bazelPath: BazelPath,
        _ bazelPathType: BazelPathType,
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
        bazelPathType: BazelPathType,
        createAttributes: ElementCreator.CreateAttributes,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    ) {
        let impliedExt = ext ?? Xcode.impliedExtension(basename: name)

        let attributes = createAttributes(
            name: name,
            bazelPath: bazelPath,
            bazelPathType: bazelPathType,
            isGroup: false
        )

        let nameAttribute: String
        if let name = attributes.elementAttributes.name {
            nameAttribute = "name = \(name.pbxProjEscaped); "
        } else {
            nameAttribute = ""
        }
        let content = """
{isa = PBXFileReference; \
\(calculateFileTypeType(basename: name, extension: impliedExt)) = \(
    impliedExt.flatMap(Xcode.pbxProjEscapedFileType) ??
        Xcode.unknownFileType
); \
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
                sortOrder: .fileLike
            ),
            resolvedRepository: attributes.resolvedRepository
        )
    }

    /// Creates a `PBXFileSystemSynchronizedRootGroup` element, which Xcode
    /// fills with the contents of the folder at `bazelPath`.
    static func synchronizedRootGroup(
        name: String,
        bazelPath: BazelPath,
        bazelPathType: BazelPathType,
        createAttributes: ElementCreator.CreateAttributes
    ) -> (
        element: Element,
        resolvedRepository: ResolvedRepository?
    ) {
        let attributes = createAttributes(
            name: name,
            bazelPath: bazelPath,
            bazelPathType: bazelPathType,
            isGroup: true
        )

        let nameAttribute: String
        if let name = attributes.elementAttributes.name {
            nameAttribute = "name = \(name.pbxProjEscaped); "
        } else {
            nameAttribute = ""
        }
        // Xcode adds the empty `explicitFileTypes` and `explicitFolders` when
        // the folder's contents change, rewriting the whole project, unless
        // they are already present.
        let content = """
{isa = PBXFileSystemSynchronizedRootGroup; \
explicitFileTypes = {}; explicitFolders = (); \
\(nameAttribute)\
path = \(attributes.elementAttributes.path.pbxProjEscaped); \
sourceTree = \(attributes.elementAttributes.sourceTree.rawValue); }
"""

        return (
            element: .init(
                name: name,
                object: .init(
                    identifier: Identifiers.FilesAndGroups
                        .synchronizedRootGroup(
                            bazelPath.path,
                            name: attributes.elementAttributes.name ??
                                attributes.elementAttributes.path
                        ),
                    content: content
                ),
                sortOrder: .groupLike
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
