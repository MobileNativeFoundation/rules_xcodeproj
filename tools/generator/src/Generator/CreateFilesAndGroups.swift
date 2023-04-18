// swiftlint:disable file_length
import Foundation
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
        internalFiles: [Path: String],
        usesExternalFileList: Bool,
        usesGeneratedFileList: Bool
    ) {
        var fileReferences: [FilePath: PBXFileReference] = [:]
        var variantGroups: [FilePath: PBXVariantGroup] = [:]
        var xcVersionGroups: [FilePath: XCVersionGroup] = [:]
        var knownRegions: Set<String> = []
        var resolvedRepositories: [(Path, Path)] = [
            ("", forFixtures ? "$(SRCROOT)" : directories.workspace),
        ]

        /// Calculates the needed `sourceTree`, `name`, and `path` for a file
        /// reference. This function exists solely to deal with symlinked
        /// external repositories. Xcode will act slow with, and fail to index,
        /// files that are under symlinks.
        func resolveFilePath(
            filePathStr: String,
            node: FileTreeNode,
            isExternal: Bool,
            isGroup: Bool
        ) -> (
            sourceTree: PBXSourceTree,
            name: String?,
            path: String
        ) {
            // `directoryLevel`` 0 is the root group
            // `directoryLevel`` 1 is "external/"
            // `directoryLevel`` 2 and 3 can be symlinks that we need to resolve
            guard isExternal && node.directoryLevel <= 3 else {
                return (
                    sourceTree: .group,
                    name: nil,
                    path: node.name
                )
            }

            // Drop "external/"
            let externalRelativePathStr = Path(String(filePathStr.dropFirst(9)))

            if let symlinkDest = try? (
                directories.absoluteExternal + externalRelativePathStr
            ).symlinkDestination() {
                let workspaceDirectoryComponents = directories
                    .workspaceComponents
                let symlinkComponents = symlinkDest.components
                if forFixtures, symlinkComponents.starts(
                    with: directories.workspaceComponents
                ) {
                    let relativeComponents = symlinkComponents.suffix(
                        from: workspaceDirectoryComponents.count
                    )
                    let relativePath = Path(components: relativeComponents)

                    if isGroup {
                        resolvedRepositories.append(
                            (
                                "/external" + externalRelativePathStr,
                                "$(SRCROOT)" + relativePath
                            )
                        )
                    }

                    return (
                        sourceTree: .sourceRoot,
                        name: node.name,
                        path: relativePath.string
                    )
                } else {
                    if isGroup {
                        resolvedRepositories.append(
                            ("/external" + externalRelativePathStr, symlinkDest)
                        )
                    }

                    return (
                        sourceTree: .absolute,
                        name: node.name,
                        path: symlinkDest.string
                    )
                }
            } else {
                return (
                    sourceTree: .group,
                    name: nil,
                    path: node.name
                )
            }
        }

        /// This function exists, instead of simply reusing
        /// `handle{FileListPath,}Node`, to be as efficient as possible when
        /// we don't need to actually create `PBXFileElement`s and just need to
        /// know what the `FilePath`s would be. This happens when an element
        /// in the tree is a "folder type file" like localized files or CoreData
        /// models.
        func collectFilePaths(
            node: FileTreeNode,
            filePathPrefix: String
        ) -> [FilePath] {
            let filePathStr = "\(filePathPrefix)\(node.name)"
            let filePath = FilePath(
                path: Path(filePathStr),
                isFolder: node.isFolder
            )

            if node.children.isEmpty {
                return [filePath]
            } else {
                let childFilePathPrefix = "\(filePathStr)/"
                var filePaths = node.children.flatMap { node in
                    collectFilePaths(
                        node: node,
                        filePathPrefix: childFilePathPrefix
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
            isExternal: Bool
        ) -> (
            filePaths: [FilePath],
            reference: PBXFileReference,
            isFileLike: Bool
        ) {
            let (sourceTree, name, path) = resolveFilePath(
                filePathStr: filePathStr,
                node: node,
                isExternal: isExternal,
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
                    }
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
                lastKnownFileType: lastKnownFileType,
                path: path
            )
            pbxProj.add(object: file)

            let filePath = FilePath(
                path: Path(filePathStr),
                isFolder: node.isFolder
            )
            fileReferences[filePath] = file

            let childFilePathPrefix = "\(filePathStr)/"
            var filePaths = node.children.flatMap { node in
                return collectFilePaths(
                    node: node,
                    filePathPrefix: childFilePathPrefix
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
            isExternal: Bool
        ) -> PBXGroup {
            let (sourceTree, name, path) = resolveFilePath(
                filePathStr: filePathStr,
                node: node,
                isExternal: isExternal,
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
            isExternal: Bool
        ) -> LocalizedFile {
            let (basenameWithoutExt, ext) = node.splitExtension()

            let file = PBXFileReference(
                sourceTree: .group,
                name: language,
                lastKnownFileType: ext
                    .flatMap { Xcode.filetype(extension: $0) },
                path: "\(parentPath)/\(node.name)"
            )
            pbxProj.add(object: file)

            let filePath = FilePath(
                path: Path(filePathStr),
                isFolder: node.isFolder
            )
            let childFilePathPrefix = "\(filePathStr)/"
            var filePaths = node.children.flatMap { node in
                return collectFilePaths(
                    node: node,
                    filePathPrefix: childFilePathPrefix
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
            isExternal: Bool
        ) -> [LocalizedFile] {
            knownRegions.insert(language)

            let (sourceTree, _, path) = resolveFilePath(
                filePathStr: filePathStr,
                node: node,
                isExternal: isExternal,
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
                        isExternal: isExternal
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
            isExternal: Bool
        ) -> XCVersionGroup {
            let (sourceTree, name, path) = resolveFilePath(
                filePathStr: filePathStr,
                node: node,
                isExternal: isExternal,
                isGroup: true
            )

            let children = node.children.map { node in
                return createFile(
                    node: node,
                    filePathStr: "\(filePathStr)/\(node.name)",
                    isExternal: isExternal
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

        /// This function exists, instead of just reusing
        /// `handleFileListPathNode`, in order to be as efficient as possible.
        /// We only need to create and collect filelist paths for the
        /// "external/" and "bazel-out/" subtrees.
        func handleNode(
            _ node: FileTreeNode,
            filePathPrefix: String,
            isExternal: Bool
        ) -> HandledNode {
            let filePathStr = "\(filePathPrefix)\(node.name)"
            let childFilePathPrefix = "\(filePathStr)/"

            if node.children.isEmpty {
                let (_, element, isFileLike) = createFile(
                    node: node,
                    filePathStr: filePathStr,
                    isExternal: isExternal
                )
                if isFileLike {
                    return .fileLikeElement(element)
                } else {
                    return .groupLikeElement(element)
                }
            } else {
                let (basenameWithoutExt, ext) = node.splitExtension()
                switch ext {
                case "lproj":
                    return .variantGroupLanguage(handleVariantGroupLanguage(
                        node: node,
                        language: basenameWithoutExt,
                        filePathStr: filePathStr,
                        isExternal: isExternal
                    ))
                case "xcdatamodeld":
                    return .fileLikeElement(createVersionGroup(
                        node: node,
                        filePathStr: filePathStr,
                        isExternal: isExternal
                    ))
                default:
                    let children = node.children.map { node in
                        return handleNode(
                            node,
                            filePathPrefix: childFilePathPrefix,
                            isExternal: isExternal
                        )
                    }
                    return .groupLikeElement(createGroup(
                        node: node,
                        children: children,
                        filePathStr: filePathStr,
                        isExternal: isExternal
                    ))
                }
            }
        }

        /// Processes a `FileTreeNode`, creating file elements and collecting
        /// filelist paths. The nodes will not be the root "bazel-out/" or
        /// "external/" nodes, those will be handled by
        /// `handleBazelGroupNode()`.
        func handleFileListPathNode(
            _ node: FileTreeNode,
            filePathPrefix: String,
            fileListPathPrefix: String,
            isExternal: Bool
        ) -> (handledNode: HandledNode, fileListPaths: [String]) {
            let filePathStr = "\(filePathPrefix)\(node.name)"
            let childFilePathPrefix = "\(filePathStr)/"
            let childFileListPathPrefix = "\(fileListPathPrefix)/\(node.name)"

            if node.children.isEmpty {
                let (_, element, isFileLike) = createFile(
                    node: node,
                    filePathStr: filePathStr,
                    isExternal: isExternal
                )
                return (
                    isFileLike ?
                        .fileLikeElement(element) : .groupLikeElement(element),
                    isExternal || !node.isFolder ?
                        [childFileListPathPrefix]: []
                )
            } else {
                let (basenameWithoutExt, ext) = node.splitExtension()
                switch ext {
                case "lproj":
                    let fileListPaths = node.children.map { node in
                        return "\(childFilePathPrefix)\(node.name)"
                    }
                    let variantGroupLanguage = handleVariantGroupLanguage(
                        node: node,
                        language: basenameWithoutExt,
                        filePathStr: filePathStr,
                        isExternal: isExternal
                    )
                    return (
                        .variantGroupLanguage(variantGroupLanguage),
                        fileListPaths
                    )
                case "xcdatamodeld":
                    let fileListPaths = node.children.map { node in
                        return "\(childFilePathPrefix)\(node.name)"
                    }
                    let group = createVersionGroup(
                        node: node,
                        filePathStr: filePathStr,
                        isExternal: isExternal
                    )
                    return (.fileLikeElement(group), fileListPaths)
                default:
                    let childrenAndFileListPaths = node.children.map { node in
                        return handleFileListPathNode(
                            node,
                            filePathPrefix: childFilePathPrefix,
                            fileListPathPrefix: childFileListPathPrefix,
                            isExternal: isExternal
                        )
                    }
                    let group = createGroup(
                        node: node,
                        children: childrenAndFileListPaths
                            .map { $0.handledNode },
                        filePathStr: filePathStr,
                        isExternal: isExternal
                    )
                    return (
                        .groupLikeElement(group),
                        childrenAndFileListPaths.flatMap { $0.fileListPaths }
                    )
                }
            }
        }

        enum BazelNodeType {
            case external
            case bazelOut
        }

        /// Handles the "bazel-out/" or "external/" root nodes. Is basically the
        /// same as `handleFileListPathNode()`.
        func handleBazelGroupNode(
            _ node: FileTreeNode,
            _ bazelNodeType: BazelNodeType
        ) -> (group: PBXGroup, fileListPaths: [String]) {
            let filePathPrefix: String
            let fileListPathPrefix: String
            let isExternal: Bool
            let groupName: String
            let groupPath: String
            switch bazelNodeType {
            case .external:
                filePathPrefix = "external/"
                fileListPathPrefix = "$(BAZEL_EXTERNAL)"
                isExternal = true
                groupName = "Bazel External Repositories"
                groupPath = "../../external"
            case .bazelOut:
                filePathPrefix = "bazel-out/"
                fileListPathPrefix = "$(BAZEL_OUT)"
                isExternal = false
                groupName = "Bazel Generated Files"
                groupPath = "bazel-out"
            }

            let childrenAndFileListPaths = node.children.map { node in
                return handleFileListPathNode(
                    node,
                    filePathPrefix: filePathPrefix,
                    fileListPathPrefix: fileListPathPrefix,
                    isExternal: isExternal
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
            if let infoPlist = target.infoPlist {
                allInputPaths.insert(infoPlist)
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
                    handleNode(node, filePathPrefix: "", isExternal: false)
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
        func addXCFileList(_ path: Path, paths: [String]) -> Bool {
            guard !paths.isEmpty else {
                return false
            }

            internalFiles[path] = Set(paths.map { "\($0)\n" }).sorted().joined()

            return true
        }

        let usesExternalFileList =
            addXCFileList(externalFileListPath, paths: externalFileListPaths)
        let usesGeneratedFileList =
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

        // TODO: Configure development region?
        knownRegions.insert("en")

        // Xcode puts "Base" last after sorting
        knownRegions.remove("Base")
        pbxProj.rootObject!.knownRegions = knownRegions.sorted() + ["Base"]

        return (
            files,
            rootElements,
            compileStub,
            resolvedRepositories,
            internalFiles,
            usesExternalFileList,
            usesGeneratedFileList
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
                throw PreconditionError(message: """
"\(xccurrentversion.container.path)" `XCVersionGroup` not found in `elements`
""")
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
