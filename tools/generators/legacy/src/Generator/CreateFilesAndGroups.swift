// swiftlint:disable file_length
import Foundation
import GeneratorCommon
import OrderedCollections
import PathKit
import XcodeProj

/// Wrapper for files (`PBXFileReference`, `PBXVariantGroup`, and
/// `XCVersionGroup`), adding additional associated data.
enum File: Equatable {
    case reference(PBXFileReference?, content: String?)
    case variantGroup(PBXVariantGroup)
    case xcVersionGroup(XCVersionGroup)
}

extension File {
    static func reference(_ reference: PBXFileReference) -> File {
        return .reference(reference, content: nil)
    }

    static func nonReferencedContent(_ content: String) -> File {
        return .reference(nil, content: content)
    }
}

extension File {
    var fileElement: PBXFileElement? {
        switch self {
        case let .reference(reference, _):
            return reference
        case let .variantGroup(group):
            return group
        case let .xcVersionGroup(group):
            return group
        }
    }
}

extension Generator {
    static let bazelForcedSwiftCompilePath: Path = "_BazelForcedCompile_.swift"
    static let compileStubPath: Path = "_CompileStub_.m"
    static let externalFileListPath: Path = "external.xcfilelist"
    static let generatedFileListPath: Path = "generated.xcfilelist"

    private static let folderTypeFileExtensions: Set<String?> = [
       "bundle",
       "docc",
       "framework",
       "scnassets",
       "xcassets",
       "xcdatamodel",
    ]

    // Most of the logic here is a modified version of
    // https://github.com/tuist/tuist/blob/a76be1d1df2ec912cbf5c4ba91a167fb1dfd0098/Sources/TuistGenerator/Generator/ProjectFileElements.swift
    // swiftlint:disable:next cyclomatic_complexity
    static func createFilesAndGroups(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        developmentRegion: String,
        forFixtures: Bool,
        targets: [TargetID: Target],
        extraFiles: Set<FilePath>,
        xccurrentversions: [XCCurrentVersion],
        directories: Directories,
        logger: Logger
    ) throws -> (
        files: [FilePath: File],
        rootElements: [PBXFileElement],
        compileStub: PBXFileReference?,
        resolvedRepositories: [(Path, Path)],
        internalFiles: [Path: String]
    ) {
        var fileReferences: [FilePath: PBXFileReference] = [:]
        var variantGroups: [FilePath: PBXVariantGroup] = [:]
        var xcVersionGroups: [FilePath: XCVersionGroup] = [:]
        var knownRegions: Set<String> = []
        var resolvedRepositories: [(Path, Path)] = [
            (".", forFixtures ? "$(SRCROOT)" : directories.workspace),
        ]

        enum BazelNodeType {
            case external
            case bazelOut
        }

        /// Calculates the needed `sourceTree`, `name`, and `path` for a file
        /// reference. This function exists solely to deal with symlinked
        /// external repositories. Xcode will act slow with, and fail to index,
        /// files that are under symlinks.
        func resolveFilePath(
            filePathStr: String,
            node: FileTreeNode,
            bazelNodeType: BazelNodeType?,
            isGroup: Bool
        ) -> (
            sourceTree: PBXSourceTree,
            name: String?,
            path: String
        ) {
            let relativePath: Path
            var absolutePath: Path
            let addToResolvedRepositories: Bool
            switch bazelNodeType {
            case .external?:
                // Drop "external/"
                relativePath = Path(String(filePathStr.dropFirst(9)))
                absolutePath = directories.absoluteExternal + relativePath
                addToResolvedRepositories = isGroup
            case .bazelOut?:
                relativePath = Path(filePathStr)
                absolutePath = directories.executionRoot + relativePath
                addToResolvedRepositories = false
            case nil:
                relativePath = Path(filePathStr)
                absolutePath = directories.workspace + relativePath
                addToResolvedRepositories = false
            }

            var wasSymlink = false
            while let symlinkDest = try? absolutePath.symlinkDestination() {
                wasSymlink = true
                absolutePath = symlinkDest
            }

            guard wasSymlink else {
                return (
                    sourceTree: .group,
                    name: nil,
                    path: node.name
                )
            }

            if forFixtures {
                let workspaceDirectoryComponents = directories
                    .workspaceComponents
                let symlinkComponents = absolutePath.components
                if symlinkComponents.starts(
                    with: directories.workspaceComponents
                ) {
                    let resolvedRelativeComponents = symlinkComponents.suffix(
                        from: workspaceDirectoryComponents.count
                    )
                    let resolvedRelativePath =
                        Path(components: resolvedRelativeComponents)

                    if addToResolvedRepositories {
                        resolvedRepositories.append(
                            (
                                "./external" + relativePath,
                                "$(SRCROOT)" + resolvedRelativePath
                            )
                        )
                    }

                    return (
                        sourceTree: .sourceRoot,
                        name: node.name,
                        path: resolvedRelativePath.string
                    )
                }
            }

            if addToResolvedRepositories {
                resolvedRepositories.append(
                    ("./external" + relativePath, absolutePath)
                )
            }

            return (
                sourceTree: .absolute,
                name: node.name,
                path: absolutePath.string
            )
        }

        /// This function exists, instead of simply reusing
        /// `handle{Non,}FileListPathNode`, to be as efficient as possible when
        /// we don't need to actually create `PBXFileElement`s and just need to
        /// know what the `FilePath`s would be. This happens when an element
        /// in the tree is a "folder type file" like localized files or CoreData
        /// models.
        func collectFilePaths(
            node: FileTreeNode,
            filePathStr: String
        ) -> [FilePath] {
            let filePath = FilePath(
                path: Path(filePathStr),
                isFolder: node.isFolder
            )

            if node.children.isEmpty {
                return [filePath]
            } else {
                var filePaths = node.children.flatMap { node in
                    collectFilePaths(
                        node: node,
                        filePathStr: "\(filePathStr)/\(node.name)"
                    )
                }
                filePaths.append(filePath)
                return filePaths
            }
        }

        /// Creates a normal file (i.e. `PBXFileReference`).
        func createFile(
            node: FileTreeNode,
            filePathStr: String,
            bazelNodeType: BazelNodeType?
        ) -> (
            filePaths: [FilePath],
            reference: PBXFileReference,
            isFileLike: Bool
        ) {
            let (sourceTree, name, path) = resolveFilePath(
                filePathStr: filePathStr,
                node: node,
                bazelNodeType: bazelNodeType,
                isGroup: false
            )

            let ext = node.extension()

            let isFileLike: Bool
            let lastKnownFileType: String?
            if node.isFolder && !folderTypeFileExtensions.contains(ext) {
                lastKnownFileType = "folder"
                isFileLike = false
            } else {
                if ext == "inc" {
                    // XcodeProj treats `.inc` files as Pascal source files, but
                    // they're commonly C/C++ headers, so map them as such here.
                    lastKnownFileType = Xcode.filetype(extension: "h")
                } else {
                    lastKnownFileType = ext.flatMap { ext in
                        return Xcode.filetype(extension: ext)
                    } ?? "file"
                }
                isFileLike = true
            }

            let explicitFileType: String?
            if node.name == "BUILD" || node.name == "BUILD.bazel" {
                explicitFileType = Xcode.filetype(extension: "py")
            } else if node.name == "Podfile" {
                explicitFileType = Xcode.filetype(extension: "rb")
            } else {
                explicitFileType = nil
            }

            let file = PBXFileReference(
                sourceTree: sourceTree,
                name: name,
                explicitFileType: explicitFileType,
                lastKnownFileType: explicitFileType == nil ?
                    lastKnownFileType : nil,
                path: path
            )
            pbxProj.add(object: file)

            let filePath = FilePath(
                path: Path(filePathStr),
                isFolder: node.isFolder
            )
            fileReferences[filePath] = file

            var filePaths = node.children.flatMap { node in
                return collectFilePaths(
                    node: node,
                    filePathStr: "\(filePathStr)/\(node.name)"
                )
            }
            filePaths.append(filePath)

            return (filePaths, file, isFileLike)
        }

        /// Creates a normal group (i.e. `PBXGroup`).
        func createGroup(
            node: FileTreeNode,
            children: [HandledNode],
            filePathStr: String,
            bazelNodeType: BazelNodeType?
        ) -> PBXGroup {
            let (sourceTree, name, path) = resolveFilePath(
                filePathStr: filePathStr,
                node: node,
                bazelNodeType: bazelNodeType,
                isGroup: true
            )

            let group = PBXGroup(
                children: children
                    .toFileElements(createVariantGroup: createVariantGroup),
                sourceTree: sourceTree,
                name: name,
                path: path
            )
            pbxProj.add(object: group)

            return group
        }

        /// Creates a `PBXFileReference` for a localized file (e.g.
        /// "en.lproj/Foo.xib") and returns it and other information that is
        /// needed to group it into the correct "variant group".
        func createLocalizedFile(
            node: FileTreeNode,
            language: String,
            sourceTree: PBXSourceTree,
            parentPath: String,
            filePathStr: String,
            bazelNodeType: BazelNodeType?
        ) -> LocalizedFile {
            let (basenameWithoutExt, ext) = node.splitExtension()

            let file = PBXFileReference(
                sourceTree: .group,
                name: language,
                lastKnownFileType: ext
                    .flatMap { Xcode.filetype(extension: $0) } ?? "file",
                path: "\(parentPath)/\(node.name)"
            )
            pbxProj.add(object: file)

            let filePath = FilePath(
                path: Path(filePathStr),
                isFolder: node.isFolder
            )
            var filePaths = node.children.flatMap { node in
                return collectFilePaths(
                    node: node,
                    filePathStr: "\(filePathStr)/\(node.name)"
                )
            }
            filePaths.append(filePath)

            return LocalizedFile(
                name: node.name,
                basenameWithoutExt: basenameWithoutExt,
                ext: ext,
                sourceTree: sourceTree,
                filePaths: filePaths,
                reference: file
            )
        }

        /// Handles a node that represents a given localization language (e.g.
        /// "en.lproj"). Returns an array of `LocalizedFile` which contains
        /// information need to group the files into "variant groups".
        func handleVariantGroupLanguage(
            node: FileTreeNode,
            language: String,
            filePathStr: String,
            bazelNodeType: BazelNodeType?
        ) -> [LocalizedFile] {
            knownRegions.insert(language)

            let (sourceTree, _, path) = resolveFilePath(
                filePathStr: filePathStr,
                node: node,
                bazelNodeType: bazelNodeType,
                isGroup: true
            )

            let localizedFiles = node.children
                .map { node in
                    return createLocalizedFile(
                        node: node,
                        language: language,
                        sourceTree: sourceTree,
                        parentPath: path,
                        filePathStr: "\(filePathStr)/\(node.name)",
                        bazelNodeType: bazelNodeType
                    )
                }

            return localizedFiles
        }

        /// Creates a grouping of localizations for a file. Xcode calls these
        /// "variant groups". The name will be the filename that has one or
        /// more localizations. For example, the variant group "Foo.xib" will
        /// have children like "Base.lproj/Foo.xib" and "en.lproj/Foo.strings".
        func createVariantGroup(
            name: String,
            sourceTree: PBXSourceTree,
            children: [PBXFileElement],
            filePaths: [FilePath]
        ) -> PBXVariantGroup {
            let variantGroup = PBXVariantGroup(
                children: children,
                sourceTree: sourceTree,
                name: name
            )
            pbxProj.add(object: variantGroup)

            // When a localized file is copied into a bundle, we should grab the
            // group instead
            filePaths.forEach {
                variantGroups[$0] = variantGroup
            }

            return variantGroup
        }

        /// Creates a ".xcdatamodel" group.
        func createVersionGroup(
            node: FileTreeNode,
            filePathStr: String,
            bazelNodeType: BazelNodeType?
        ) -> XCVersionGroup {
            let (sourceTree, name, path) = resolveFilePath(
                filePathStr: filePathStr,
                node: node,
                bazelNodeType: bazelNodeType,
                isGroup: true
            )

            let children = node.children.map { node in
                return createFile(
                    node: node,
                    filePathStr: "\(filePathStr)/\(node.name)",
                    bazelNodeType: bazelNodeType
                )
            }

            let xcVersionGroup = XCVersionGroup(
                path: path,
                name: name,
                sourceTree: sourceTree,
                versionGroupType: "wrapper.xcdatamodel",
                children: children.map { $0.reference }
            )
            pbxProj.add(object: xcVersionGroup)

            let filePath = FilePath(
                path: Path(filePathStr),
                isFolder: false
            )
            xcVersionGroups[filePath] = xcVersionGroup

            // When a model file is copied into a bundle, we should grab the
            // group instead
            children.forEach {
                $0.filePaths.forEach { xcVersionGroups[$0] = xcVersionGroup }
            }

            return xcVersionGroup
        }

        enum SemiHandledNode {
            case file(HandledNode)
            case group(HandledNode, fileListPaths: [String])
            case specialGroup(HandledNode)

            var handledNode: HandledNode {
                switch self {
                case .file(let handledNode): return handledNode
                case .group(let handledNode, _): return handledNode
                case .specialGroup(let handledNode): return handledNode
                }
            }
        }

        /// Consolidates most of the logic between `handleNonFileListPathNode()`
        /// and `handleFileListPathNode()`.
        func handleNode(
            _ node: FileTreeNode,
            bazelNodeType: BazelNodeType?,
            filePathStr: String,
            handleGroupNode: () -> (
                children: [HandledNode],
                fileListPaths: [String]
            )
        ) -> SemiHandledNode {
            if node.children.isEmpty {
                let (_, element, isFileLike) = createFile(
                    node: node,
                    filePathStr: filePathStr,
                    bazelNodeType: bazelNodeType
                )
                if isFileLike {
                    return .file(.fileLikeElement(element))
                } else {
                    return .file(.groupLikeElement(element))
                }
            } else {
                let (basenameWithoutExt, ext) = node.splitExtension()
                switch ext {
                case "lproj":
                    return .specialGroup(
                        .variantGroupLanguage(handleVariantGroupLanguage(
                            node: node,
                            language: basenameWithoutExt,
                            filePathStr: filePathStr,
                            bazelNodeType: bazelNodeType
                        ))
                    )
                case "xcdatamodeld":
                    return .specialGroup(
                        .fileLikeElement(createVersionGroup(
                            node: node,
                            filePathStr: filePathStr,
                            bazelNodeType: bazelNodeType
                        ))
                    )
                default:
                    let (children, fileListPaths) = handleGroupNode()
                    return .group(
                        .groupLikeElement(createGroup(
                            node: node,
                            children: children,
                            filePathStr: filePathStr,
                            bazelNodeType: bazelNodeType
                        )),
                        fileListPaths: fileListPaths
                    )
                }
            }
        }

        /// This function exists, instead of just reusing
        /// `handleFileListPathNode`, in order to be as efficient as possible.
        /// We only need to create and collect filelist paths for the
        /// "external/" and "bazel-out/" subtrees.
        func handleNonFileListPathNode(
            _ node: FileTreeNode,
            filePathStr: String
        ) -> HandledNode {
            let semiHandledNode = handleNode(
                node,
                bazelNodeType: nil,
                filePathStr: filePathStr,
                handleGroupNode: {
                    return (
                        children: node.children.map { node in
                            return handleNonFileListPathNode(
                                node,
                                filePathStr: "\(filePathStr)/\(node.name)"
                            )
                        },
                        fileListPaths: []
                    )
                }
            )
            return semiHandledNode.handledNode
        }

        /// Processes a `FileTreeNode`, creating file elements and collecting
        /// filelist paths. The nodes will not be the root "bazel-out/" or
        /// "external/" nodes, those will be handled by
        /// `handleBazelGroupNode()`.
        func handleFileListPathNode(
            _ node: FileTreeNode,
            filePathStr: String,
            fileListPathStr: String,
            bazelNodeType: BazelNodeType
        ) -> (handledNode: HandledNode, fileListPaths: [String]) {
            let semiHandledNode = handleNode(
                node,
                bazelNodeType: bazelNodeType,
                filePathStr: filePathStr,
                handleGroupNode: {
                    let childrenAndFileListPaths = node.children.map { node in
                        return handleFileListPathNode(
                            node,
                            filePathStr: "\(filePathStr)/\(node.name)",
                            fileListPathStr: "\(fileListPathStr)/\(node.name)",
                            bazelNodeType: bazelNodeType
                        )
                    }

                    return (
                        children: childrenAndFileListPaths
                            .map { $0.handledNode },
                        fileListPaths: childrenAndFileListPaths
                            .flatMap { $0.fileListPaths }
                    )
                }
            )

            switch semiHandledNode {
            case .file(let handledNode):
                let fileListPaths: [String]
                if bazelNodeType == .external || !node.isFolder {
                    fileListPaths = [fileListPathStr]
                } else {
                    fileListPaths = []
                }
                return (handledNode, fileListPaths)

            case .specialGroup(let handledNode):
                let fileListPaths = node.children.map { node in
                    return "\(fileListPathStr)/\(node.name)"
                }
                return (handledNode, fileListPaths)

            case .group(let handledNode, let fileListPaths):
                return (handledNode, fileListPaths)
            }
        }

        /// Handles the "bazel-out/" or "external/" root nodes. Is basically the
        /// same as `handleFileListPathNode()`.
        func handleBazelGroupNode(
            _ node: FileTreeNode,
            _ bazelNodeType: BazelNodeType
        ) -> (group: PBXGroup, fileListPaths: [String]) {
            let filePathStr: String
            let fileListPathStr: String
            let groupName: String
            let groupPath: String
            switch bazelNodeType {
            case .external:
                filePathStr = "external"
                fileListPathStr = "$(BAZEL_EXTERNAL)"
                groupName = "Bazel External Repositories"
                groupPath = "../../external"
            case .bazelOut:
                filePathStr = "bazel-out"
                fileListPathStr = "$(BAZEL_OUT)"
                groupName = "Bazel Generated Files"
                groupPath = "bazel-out"
            }

            let childrenAndFileListPaths = node.children.map { node in
                return handleFileListPathNode(
                    node,
                    filePathStr: "\(filePathStr)/\(node.name)",
                    fileListPathStr: "\(fileListPathStr)/\(node.name)",
                    bazelNodeType: bazelNodeType
                )
            }

            let group = PBXGroup(
                children: childrenAndFileListPaths.lazy.map(\.handledNode)
                    .toFileElements(createVariantGroup: createVariantGroup),
                sourceTree: .sourceRoot,
                name: groupName,
                path: groupPath
            )
            pbxProj.add(object: group)

            return (
                group,
                childrenAndFileListPaths.flatMap { $0.fileListPaths }
            )
        }

        // Collect all files
        var createCompileStub = false
        var allInputPaths = extraFiles
        for target in targets.values {
            if let cParams = target.cParams {
                allInputPaths.insert(cParams)
            }
            if let cxxParams = target.cxxParams {
                allInputPaths.insert(cxxParams)
            }
            if let swiftParams = target.swiftParams {
                allInputPaths.insert(swiftParams)
            }
            if let linkParams = target.linkParams {
                allInputPaths.insert(linkParams)
            }
            allInputPaths.formUnion(target.inputs.all)
            allInputPaths.formUnion(
                target.outputs.forcedBazelCompileFiles(buildMode: buildMode)
            )
            if !target.inputs.containsSources,
                target.product.type.hasCompilePhase,
                target.product.path != nil
            {
                createCompileStub = true
            }
        }

        let rootNode = try calculateFileTree(filePaths: allInputPaths)

        var externalGroup: PBXGroup?
        var generatedGroup: PBXGroup?
        var handledNodes: [HandledNode] = []
        var externalFileListPaths: [String] = []
        var generatedFileListPaths: [String] = []
        for node in rootNode.children {
            switch node.name {
            case "external":
                (
                    externalGroup,
                    externalFileListPaths
                ) = handleBazelGroupNode(node, .external)
            case "bazel-out":
                (
                    generatedGroup,
                    generatedFileListPaths
                ) = handleBazelGroupNode(node, .bazelOut)
            default:
                handledNodes.append(
                    handleNonFileListPathNode(node, filePathStr: node.name)
                )
            }
        }

        var rootElements = handledNodes
            .toFileElements(createVariantGroup: createVariantGroup)

        var internalGroup: PBXGroup?
        var compileStub: PBXFileReference?
        if createCompileStub {
            let file = PBXFileReference(
                sourceTree: .custom("DERIVED_FILE_DIR"),
                name: nil,
                lastKnownFileType: Xcode.filetype(extension: "m"),
                path: compileStubPath.string
            )
            pbxProj.add(object: file)
            compileStub = file

            let group = PBXGroup(
                children: [file],
                sourceTree: .group,
                name: directories.internalDirectoryName,
                path: directories.internal.string
            )
            pbxProj.add(object: group)
            internalGroup = group
        }

        try setXCCurrentVersions(
            xcVersionGroups: xcVersionGroups,
            xccurrentversions: xccurrentversions,
            logger: logger
        )

        var files: [FilePath: File] = [:]
        for (filePath, fileReference) in fileReferences {
            files[filePath] = .reference(fileReference)
        }
        for (filePath, variantGroup) in variantGroups {
            files[filePath] = .variantGroup(variantGroup)
        }
        for (filePath, xcVersionGroup) in xcVersionGroups {
            files[filePath] = .xcVersionGroup(xcVersionGroup)
        }

        // Write xcfilelists

        var internalFiles: [Path: String] = [:]
        func addXCFileList(_ path: Path, paths: [String]) {
            internalFiles[path] = Set(paths.map { "\($0)\n" }).sorted().joined()
        }

        addXCFileList(externalFileListPath, paths: externalFileListPaths)
        addXCFileList(generatedFileListPath, paths: generatedFileListPaths)

        // Handle special groups. We add these groups last to ensure their
        // order, which is different from normal sorting. They need to come
        // after the normal files and groups.
        if let externalGroup = externalGroup {
            rootElements.append(externalGroup)
        }
        if let generatedGroup = generatedGroup {
            rootElements.append(generatedGroup)
        }
        if let internalGroup = internalGroup {
            rootElements.append(internalGroup)
        }

        knownRegions.insert(developmentRegion)

        // Xcode puts "Base" last after sorting
        knownRegions.remove("Base")
        pbxProj.rootObject!.knownRegions = knownRegions.sorted() + ["Base"]

        return (
            files,
            rootElements,
            compileStub,
            resolvedRepositories,
            internalFiles
        )
    }

    private static func setXCCurrentVersions(
        xcVersionGroups: [FilePath: XCVersionGroup],
        xccurrentversions: [XCCurrentVersion],
        logger: Logger
    ) throws {
        for xccurrentversion in xccurrentversions {
            guard
                let xcVerisonGroup = xcVersionGroups[xccurrentversion.container]
            else {
                // We can get `.xccurrentversion` files for `.xcdatamodel`
                // bundles that are uncategorized (e.g.
                // `rules_ios_apple_framework.resource_bundles`). If no
                // downstream target is focused, we won't have an
                // `xcVersionGroups` for this `xccurrentversion`. We can safely
                // ignore these.
                continue
            }

            guard
                let versionChild = xcVerisonGroup.children
                    .first(where: { $0.path == xccurrentversion.version })
            else {
                logger.logWarning("""
"\(xccurrentversion.container.path)" doesn't have \
"\(xccurrentversion.version)" as a child; not setting `currentVersion`
""")
                continue
            }

            guard let versionFile = versionChild as? PBXFileReference else {
                throw PreconditionError(message: """
"\(versionChild.path!)" is not a `PBXFileReference`
""")
            }

            xcVerisonGroup.currentVersion = versionFile
        }
    }

    private static func calculateFileTree(
        filePaths: Set<FilePath>
    ) throws -> FileTreeNode {
        guard !filePaths.isEmpty else {
            throw PreconditionError(message: "`filePaths` was empty")
        }

        var nodesByComponentCount: [Int: [FileTreeNodeToVisit]] = [:]
        for filePath in filePaths {
            let components = filePath.path.string.split(separator: "/")
            nodesByComponentCount[components.count, default: []]
                .append(FileTreeNodeToVisit(
                    components: components,
                    isFolder: filePath.isFolder,
                    children: []
                ))
        }

        for componentCount in (1...nodesByComponentCount.keys.max()!)
            .reversed()
        {
            let nodes = nodesByComponentCount
                .removeValue(forKey: componentCount)!

            let sortedNodes = nodes.sorted { lhs, rhs in
                // Already bucketed to have the same component count, so we
                // don't sort on count first

                for i in lhs.components.indices {
                   let lhsComponent = lhs.components[i]
                   let rhsComponent = rhs.components[i]
                   guard lhsComponent == rhsComponent else {
                       // We properly sort in `toFileElements()`, so we do a
                       // simple version here
                       return lhsComponent < rhsComponent
                   }
                }

                guard lhs.isFolder == rhs.isFolder else {
                    return lhs.isFolder
                }

                return false
            }

            // Create parent nodes

            let firstNode = sortedNodes[0]
            var collectingParentComponents = firstNode.components.dropLast(1)
            var collectingParentChildren: [FileTreeNode] = []
            var nodesForNextComponentCount: [FileTreeNodeToVisit] = []

            for node in sortedNodes {
                let parentComponents = node.components.dropLast(1)
                if parentComponents != collectingParentComponents {
                    nodesForNextComponentCount.append(
                        FileTreeNodeToVisit(
                            components: Array(collectingParentComponents),
                            children: collectingParentChildren
                        )
                    )

                    collectingParentComponents = parentComponents
                    collectingParentChildren = []
                }

                collectingParentChildren.append(
                    FileTreeNode(
                        name: String(node.components.last!),
                        isFolder: node.isFolder,
                        directoryLevel: componentCount,
                        children: node.children
                    )
                )
            }

            guard componentCount != 1 else {
                // Root node
                return FileTreeNode(
                    name: "",
                    directoryLevel: 0,
                    children: collectingParentChildren
                )
            }

            // Last node
            nodesForNextComponentCount.append(
                FileTreeNodeToVisit(
                    components: Array(collectingParentComponents),
                    children: collectingParentChildren
                )
            )

            nodesByComponentCount[componentCount - 1, default: []]
                .append(contentsOf: nodesForNextComponentCount)
        }

        fatalError("Unreachable")
    }
}

private class FileTreeNodeToVisit {
    let components: [String.SubSequence]
    let isFolder: Bool
    let children: [FileTreeNode]

    init(
        components: [String.SubSequence],
        isFolder: Bool = false,
        children: [FileTreeNode]
    ) {
        self.components = components
        self.isFolder = isFolder
        self.children = children
    }
}

extension FileTreeNodeToVisit: CustomDebugStringConvertible {
    var debugDescription: String {
        return #""\#(components.last!)": {\#(children.map { $0.name }.joined(separator: ","))}"#
    }
}

private class FileTreeNode {
    let name: String
    let isFolder: Bool
    let directoryLevel: Int
    let children: [FileTreeNode]

    init(
        name: String,
        isFolder: Bool = false,
        directoryLevel: Int,
        children: [FileTreeNode]
    ) {
        self.name = name
        self.isFolder = isFolder
        self.directoryLevel = directoryLevel
        self.children = children
    }
}

extension FileTreeNode {
    func `extension`() -> String? {
        guard let extIndex = name.lastIndex(of: ".") else {
            return nil
        }
        return String(name[name.index(after: extIndex)..<name.endIndex])
    }

    func splitExtension() -> (base: String, ext: String?) {
        guard let extIndex = name.lastIndex(of: ".") else {
            return (name, nil)
        }
        return (
            String(name[name.startIndex..<extIndex]),
            String(name[name.index(after: extIndex)..<name.endIndex])
        )
    }
}

private enum HandledNode {
    case fileLikeElement(PBXFileElement)
    case groupLikeElement(PBXFileElement)
    case variantGroupLanguage([LocalizedFile])
}

private struct LocalizedFile {
    let name: String
    let basenameWithoutExt: String
    let ext: String?
    let sourceTree: PBXSourceTree
    let filePaths: [FilePath]
    let reference: PBXFileReference
}

private let localizedIBFileExtensions: OrderedSet<String?> = [
    "storyboard",
    "xib",
    "intentdefinition",
]

extension Sequence where Element == HandledNode {
    func toFileElements(
        createVariantGroup: (
            _ name: String,
            _ sourceTree: PBXSourceTree,
            _ children: [PBXFileElement],
            _ filePaths: [FilePath]
        ) -> PBXVariantGroup
    ) -> [PBXFileElement] {
        var fileLikeElements: [PBXFileElement] = []
        var groupLikeElements: [PBXFileElement] = []
        var localizedFiles: [LocalizedFile] = []

        for handledNode in self {
            switch handledNode {
            case .fileLikeElement(let element):
                fileLikeElements.append(element)
            case .groupLikeElement(let element):
                groupLikeElements.append(element)
            case .variantGroupLanguage(let languageLocalizedFiles):
                localizedFiles.append(contentsOf: languageLocalizedFiles)
            }
        }

        localizedFiles.sort(by: { lhs, rhs in
            switch (lhs.ext, rhs.ext) {
            case ("intentdefinition", "intentdefinition"): return false
            case ("intentdefinition", _): return true
            case (_, "intentdefinition"): return false
            case ("storyboard", "storyboard"): return false
            case ("storyboard", _): return true
            case (_, "storyboard"): return false
            case ("xib", "xib"): return false
            case ("xib", _): return true
            case (_, "xib"): return false
            case ("strings", "strings"): return false
            case ("strings", _): return true
            case (_, "strings"): return false
            // The order of other files should stay the same
            default: return false
            }
        })

        var groupings: OrderedDictionary<String, [LocalizedFile]> = [:]
        outer: for localizedFile in localizedFiles {
            if localizedFile.ext == "strings" {
                // Attempt to add the ".strings" file to an IB file of the
                // same name. Since we sorted `localizedFiles`, the "parent"
                // group will already be in `groupings`.
                let keys = groupings.keys

                for ext in localizedIBFileExtensions {
                    let key = "\(localizedFile.basenameWithoutExt).\(ext!)"
                    if keys.contains(key) {
                        groupings[key]!.append(localizedFile)
                        continue outer
                    }
                }

                // Didn't find a parent, fall through to non-IB handling
            }

            groupings[localizedFile.name, default: []].append(localizedFile)
        }

        for (name, localizedFiles) in groupings {
            fileLikeElements.append(
                createVariantGroup(
                    name,
                    localizedFiles.first!.sourceTree,
                    localizedFiles.map { $0.reference },
                    localizedFiles.flatMap { $0.filePaths }
                )
            )
        }

        return groupLikeElements.sortedLocalizedStandard() +
            fileLikeElements.sortedLocalizedStandard()
    }
}

// MARK: - Extensions

private extension Inputs {
    var containsSources: Bool { !srcs.isEmpty || !nonArcSrcs.isEmpty }
}

private extension Outputs {
    func forcedBazelCompileFiles(buildMode _: BuildMode) -> Set<FilePath> {
        // TODO: Re-enable for Swift diagnostics replay
//        if buildMode.usesBazelModeBuildScripts, swift != nil {
//            return [.internal(Generator.bazelForcedSwiftCompilePath)]
//        }

        return []
    }
}
