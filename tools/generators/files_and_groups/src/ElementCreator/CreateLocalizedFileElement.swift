import PBXProj

extension ElementCreator {
    struct CreateLocalizedFileElement {
        private let createIdentifier: CreateIdentifier

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createIdentifier: CreateIdentifier,
            callable: @escaping Callable
        ) {
            self.createIdentifier = createIdentifier

            self.callable = callable
        }

        /// Creates a localized `PBXFileReference` element.
        func callAsFunction(
            name: String,
            nameNeedsPBXProjEscaping: Bool,
            path: String,
            pathNeedsPBXProjEscaping: Bool,
            ext: String?,
            bazelPath: BazelPath
        ) -> Element {
            return callable(
                /*name:*/ name,
                /*nameNeedsPBXProjEscaping:*/ nameNeedsPBXProjEscaping,
                /*path:*/ path,
                /*pathNeedsPBXProjEscaping:*/ pathNeedsPBXProjEscaping,
                /*ext:*/ ext,
                /*bazelPath:*/ bazelPath,
                /*createIdentifier:*/ createIdentifier
            )
        }
    }
}

// MARK: - CreateLocalizedFileElement.Callable

extension ElementCreator.CreateLocalizedFileElement {
    typealias Callable = (
        _ name: String,
        _ nameNeedsPBXProjEscaping: Bool,
        _ path: String,
        _ pathNeedsPBXProjEscaping: Bool,
        _ ext: String?,
        _ bazelPath: BazelPath,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> Element

    static func defaultCallable(
        name: String,
        nameNeedsPBXProjEscaping: Bool,
        path: String,
        pathNeedsPBXProjEscaping: Bool,
        ext: String?,
        bazelPath: BazelPath,
        createIdentifier: ElementCreator.CreateIdentifier
    ) -> Element {
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
            fileType = ext
                .flatMap { Xcode.pbxProjEscapedFileType(extension: $0) } ??
                "file"
        }

        // TODO: Find a way to have path be escaped ahead of time. If we know
        // that any node name needs to be escaped, we can escape the full path.
        // Should be faster to check each component once. Can apply to `name` as
        // well.

        let content = """
{isa = PBXFileReference; \
\(fileTypeType) = \(fileType); \
name = \(nameNeedsPBXProjEscaping ? name.pbxProjEscapedWithoutCheck : name); \
path = \(pathNeedsPBXProjEscaping ? path.pbxProjEscapedWithoutCheck : path); \
sourceTree = "<group>"; }
"""

        return .init(
            name: name,
            object: .init(
                identifier: createIdentifier(
                    path: bazelPath.path,
                    name: name,
                    type: .localized
                ),
                content: content
            ),
            sortOrder: .fileLike
        )
    }
}
