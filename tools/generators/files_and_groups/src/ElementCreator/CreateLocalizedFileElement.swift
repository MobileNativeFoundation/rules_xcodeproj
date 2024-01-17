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
            path: String,
            ext: String?,
            bazelPath: BazelPath
        ) -> Element {
            return callable(
                /*name:*/ name,
                /*path:*/ path,
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
        _ path: String,
        _ ext: String?,
        _ bazelPath: BazelPath,
        _ createIdentifier: ElementCreator.CreateIdentifier
    ) -> Element

    static func defaultCallable(
        name: String,
        path: String,
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

        let content = """
{isa = PBXFileReference; \
\(fileTypeType) = \(fileType); \
name = \(name.pbxProjEscaped); \
path = \(path.pbxProjEscaped); \
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
