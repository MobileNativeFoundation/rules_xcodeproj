import PBXProj

extension ElementCreator {
    /// Calculates the `sourceTree`, `name`, and `path` attributes for an
    /// element.
    ///
    /// This function exists solely to deal with symlinked external
    /// repositories. Xcode will act slow with, and fail to index, files that
    /// are under symlinks.
    ///
    /// If an external repository symlink was resolved, then the returned
    /// `resolvedRepository` will be non-`nil`.
    ///
    /// - Parameters:
    ///   - name: This element's `node.name`.
    ///   - bazelPath: The `BazelPath` for the node.
    ///   - isGroup: `true` if this a group element (e.g. `PBXGroup`,
    ///     `XCVersionGroup`, etc.).
    ///   - specialRootGroupType: The `SpecialRootGroupType` this element is
    ///     under. For example, if this element is for a Bazel generated file,
    ///     `specialRootGroupType` will be `.bazelGenerated`. If this element is
    ///     for a file in the workspace, `specialRootGroupType` will be `nil`.
    ///   - executionRoot: The absolute path to Bazel's execution root.
    ///   - externalDir: The absolute path to Bazel's external repository
    ///     directory.
    ///   - workspace: The absolute path to the Bazel workspace.
    ///   - resolveSymlink: A function that takes a path, and if it's a symlink,
    ///     recursively resolves it to an absolute path. If the path isn't to a
    ///     symlink, it returns `nil`.
    static func attributes(
        name: String,
        bazelPath: BazelPath,
        isGroup: Bool,
        specialRootGroupType: SpecialRootGroupType?,
        executionRoot: String,
        externalDir: String,
        workspace: String,
        resolveSymlink: (_ path: String) -> String?
    ) -> (
        elementAttributes: ElementAttributes,
        resolvedRepository: ResolvedRepository?
    ) {
        let relativePath: String.SubSequence
        var absolutePath: String
        let resolvedRepositoryPrefix: String?
        switch specialRootGroupType {
        case .legacyBazelExternal?:
            // Drop "external/"
            relativePath = bazelPath.path.dropFirst(9)
            absolutePath = "\(externalDir)/\(relativePath)"
            resolvedRepositoryPrefix = isGroup ? "./external/" : nil

        case .siblingBazelExternal?:
            // Drop "../"
            relativePath = bazelPath.path.dropFirst(3)
            absolutePath = "\(externalDir)/\(relativePath)"
            resolvedRepositoryPrefix = isGroup ? "../" : nil

        case .bazelGenerated?:
            relativePath = String.SubSequence(bazelPath.path)
            absolutePath = "\(executionRoot)/\(relativePath)"
            resolvedRepositoryPrefix = nil
            
        case nil:
            relativePath = String.SubSequence(bazelPath.path)
            absolutePath = "\(workspace)/\(relativePath)"
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

struct ElementAttributes {
    let sourceTree: SourceTree
    let name: String?
    let path: String
}

struct ElementAttributesEnvironment {
    let externalDir: String
    let executionRoot: String
    let workspace: String
    let resolveSymlink: (_ path: String) -> String?
}
