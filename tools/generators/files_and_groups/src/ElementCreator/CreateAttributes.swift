import PBXProj

struct ElementAttributes {
    let sourceTree: SourceTree
    let name: String?
    let path: String
}

extension ElementCreator {
    struct CreateAttributes {
        private let executionRoot: String
        private let externalDir: String
        private let workspace: String
        private let resolveSymlink: ResolveSymlink

        private let callable: Callable

        /// - Parameters:
        ///   - executionRoot: The absolute path to Bazel's execution root.
        ///   - externalDir: The absolute path to Bazel's external repository
        ///     directory.
        ///   - workspace: The absolute path to the Bazel workspace.
        ///   - resolveSymlink: A function that takes a path, and if it's a
        ///     symlink, recursively resolves it to an absolute path. If the
        ///     path isn't to a symlink, it returns `nil`.
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            executionRoot: String,
            externalDir: String,
            workspace: String,
            resolveSymlink: ResolveSymlink,
            callable: @escaping Callable
        ) {
            self.executionRoot = executionRoot
            self.externalDir = externalDir
            self.workspace = workspace
            self.resolveSymlink = resolveSymlink

            self.callable = callable
        }

        /// Calculates the `sourceTree`, `name`, and `path` attributes for an
        /// element.
        ///
        /// This function exists solely to deal with symlinked external
        /// repositories. Xcode will act slow with, and fail to index, files
        /// that are under symlinks.
        ///
        /// If an external repository symlink was resolved, then the returned
        /// `resolvedRepository` will be non-`nil`.
        ///
        /// - Parameters:
        ///   - name: This element's `node.name`.
        ///   - bazelPath: The `BazelPath` for the node.
        ///   - isGroup: `true` if this a group element (e.g. `PBXGroup`,
        ///     `XCVersionGroup`, etc.).
        ///   - bazelPathType: The type of path that `BazelPath` represents.
        ///     For example, if this element is for a Bazel generated file,
        ///    `bazelPathType` will be `.bazelGenerated`. If this element is for
        ///     a file in the workspace, `bazelPathType` will be `.workspace`.
        func callAsFunction(
            name: String,
            bazelPath: BazelPath,
            bazelPathType: BazelPathType,
            isGroup: Bool
        ) -> (
            elementAttributes: ElementAttributes,
            resolvedRepository: ResolvedRepository?
        ) {
            return callable(
                /*name:*/ name,
                /*bazelPath:*/ bazelPath,
                /*bazelPathType:*/ bazelPathType,
                /*isGroup:*/ isGroup,
                /*executionRoot:*/ executionRoot,
                /*externalDir:*/ externalDir,
                /*workspace:*/ workspace,
                /*resolveSymlink:*/ resolveSymlink
            )
        }
    }
}

// MARK: - CreateAttributes.Callable

extension ElementCreator.CreateAttributes {
    typealias Callable = (
        _ name: String,
        _ bazelPath: BazelPath,
        _ bazelPathType: BazelPathType,
        _ isGroup: Bool,
        _ executionRoot: String,
        _ externalDir: String,
        _ workspace: String,
        _ resolveSymlink: ElementCreator.ResolveSymlink
    ) -> (
        elementAttributes: ElementAttributes,
        resolvedRepository: ResolvedRepository?
    )

    static func defaultCallable(
        name: String,
        bazelPath: BazelPath,
        bazelPathType: BazelPathType,
        isGroup: Bool,
        executionRoot: String,
        externalDir: String,
        workspace: String,
        resolveSymlink: ElementCreator.ResolveSymlink
    ) -> (
        elementAttributes: ElementAttributes,
        resolvedRepository: ResolvedRepository?
    ) {
        let relativePath: String.SubSequence
        var absolutePath: String
        let resolvedRepositoryPrefix: String?
        switch bazelPathType {
        case .workspace:
            relativePath = String.SubSequence(bazelPath.path)
            absolutePath = "\(workspace)/\(relativePath)"
            resolvedRepositoryPrefix = nil

        case .legacyBazelExternal:
            // Drop "external/"
            relativePath = bazelPath.path.dropFirst(9)
            absolutePath = "\(externalDir)/\(relativePath)"
            resolvedRepositoryPrefix = isGroup ? "./external/" : nil

        case .siblingBazelExternal:
            // Drop "../"
            relativePath = bazelPath.path.dropFirst(3)
            absolutePath = "\(externalDir)/\(relativePath)"
            resolvedRepositoryPrefix = isGroup ? "../" : nil

        case .bazelGenerated:
            relativePath = String.SubSequence(bazelPath.path)
            absolutePath = "\(executionRoot)/\(relativePath)"
            resolvedRepositoryPrefix = nil
        }

        guard let symlinkDest = resolveSymlink(absolutePath) else {
            return (
                elementAttributes: ElementAttributes(
                    sourceTree: .group,
                    name: nil,
                    path: name
                ),
                resolvedRepository: nil
            )
        }

        let resolvedRepository: ResolvedRepository?
        if let resolvedRepositoryPrefix {
            resolvedRepository = .init(
                sourcePath: "\(resolvedRepositoryPrefix)\(relativePath)",
                mappedPath: symlinkDest
            )
        } else {
            resolvedRepository = nil
        }

        return (
            elementAttributes: ElementAttributes(
                sourceTree: .absolute,
                name: name,
                path: symlinkDest
            ),
            resolvedRepository: resolvedRepository
        )
    }
}

enum BazelPathType {
    case bazelGenerated
    case legacyBazelExternal
    case siblingBazelExternal
    case workspace
}
