// swiftlint:disable file_length
import Foundation
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

    private static let localizedGroupExtensions: Set<String> = [
        "intentdefinition",
        "storyboard",
        "strings",
        "xib",
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
        var normalGroups: [FilePath: PBXGroup] = [:]
        var variantGroups: [FilePath: PBXVariantGroup] = [:]
        var xcVersionGroups: [FilePath: XCVersionGroup] = [:]
        var knownRegions: Set<String> = []
        var resolvedRepositories: [(Path, Path)] = [
            ("", forFixtures ? "$(SRCROOT)" : directories.workspace),
        ]

        func resolveFilePath(
            _ filePath: FilePath,
            pathComponent: String,
            isGroup: Bool
        ) -> (
            sourceTree: PBXSourceTree,
            name: String?,
            path: String
        ) {
            if filePath.type == .external,
                filePath.path.components.count <= 2,
               let symlinkDest = try? (
                directories.absoluteExternal + filePath.path
               ).symlinkDestination()
            {
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
                                "/external" + filePath.path,
                                "$(SRCROOT)" + relativePath
                            )
                        )
                    }

                    return (
                        sourceTree: .sourceRoot,
                        name: pathComponent,
                        path: relativePath.string
                    )
                } else {
                    if isGroup {
                        resolvedRepositories.append(
                            ("/external" + filePath.path, symlinkDest)
                        )
                    }

                    return (
                        sourceTree: .absolute,
                        name: pathComponent,
                        path: symlinkDest.string
                    )
                }
            } else {
                return (
                    sourceTree: .group,
                    name: nil,
                    path: pathComponent
                )
            }
        }

        func createElement(
            in pbxProj: PBXProj,
            filePath: FilePath,
            pathComponent: String,
            parentIsLocalizedContainer: Bool,
            isLeaf: Bool,
            forceGroupCreation: Bool
        ) -> (PBXFileElement, isNew: Bool)? {
            if filePath.path.isLocalizedContainer {
                // Localized container (e.g. /path/to/en.lproj)
                // We don't add it directly; an element will get added once the
                // next path component is evaluated.
                return nil
            } else if parentIsLocalizedContainer {
                // Localized file (e.g. /path/to/en.lproj/foo.png)
                if let variantGroup = variantGroups[filePath] {
                    return (variantGroup, false)
                }
                return addLocalizedFile(filePath: filePath)
            } else if filePath.path.isCoreDataContainer {
                if let xcVersionGroup = xcVersionGroups[filePath] {
                    return (xcVersionGroup, false)
                }

                let (sourceTree, name, path) = resolveFilePath(
                    filePath,
                    pathComponent: pathComponent,
                    isGroup: true
                )

                let xcVersionGroup = XCVersionGroup(
                    path: path,
                    name: name,
                    sourceTree: sourceTree,
                    versionGroupType: filePath.path.versionGroupType
                )
                pbxProj.add(object: xcVersionGroup)

                xcVersionGroups[filePath] = xcVersionGroup

                return (xcVersionGroup, true)
            } else if !isLeaf, forceGroupCreation || !filePath.path.isFolderTypeFileSource {
                if let group = normalGroups[filePath] {
                    return (group, false)
                }

                let group = createGroup(
                    filePath: filePath,
                    pathComponent: pathComponent
                )
                return (group, true)
            } else {
                if let fileReference = fileReferences[filePath] {
                    return (fileReference, false)
                }

                let (sourceTree, name, path) = resolveFilePath(
                    filePath,
                    pathComponent: pathComponent,
                    isGroup: false
                )

                let lastKnownFileType: String?
                if filePath.isFolder, !filePath.path.isFolderTypeFileSource {
                    lastKnownFileType = "folder"
                } else {
                    lastKnownFileType = filePath.path.lastKnownFileType
                }
                let file = PBXFileReference(
                    sourceTree: sourceTree,
                    name: name,
                    explicitFileType: filePath.path.explicitFileType,
                    lastKnownFileType: lastKnownFileType,
                    path: path
                )
                pbxProj.add(object: file)

                fileReferences[filePath] = file

                return (file, true)
            }
        }

        func createGroup(
            filePath: FilePath,
            pathComponent: String
        ) -> PBXGroup {
            let (sourceTree, name, path) = resolveFilePath(
                filePath,
                pathComponent: pathComponent,
                isGroup: true
            )

            let group = PBXGroup(
                sourceTree: sourceTree,
                name: name,
                path: path
            )
            pbxProj.add(object: group)
            normalGroups[filePath] = group

            return group
        }

        func addLocalizedFile(
            filePath: FilePath
        ) -> (PBXVariantGroup, isNew: Bool) {
            // e.g. App.strings
            let fileName = filePath.path.lastComponent
            // e.g. resources/en.lproj
            let localizedContainerFilePath = filePath.parent()
            // e.g. resources/App.strings
            let groupFilePath = localizedContainerFilePath.parent() + fileName

            // TODO: Use `resolveFilePath`?

            // Variant group
            let variantGroup: PBXVariantGroup
            let isNew: Bool
            if let existingGroup = existingVariantGroup(containing: filePath) {
                isNew = false
                variantGroup = existingGroup.group
                // For variant groups formed by Interface Builder files (".xib"
                // or ".storyboard") and corresponding ".strings" files, name
                // and path of the group must have the extension of the
                // Interface Builder file. Since the order in which such groups
                // are formed is not deterministic, we must change the name and
                // path here as necessary.
                if ["xib", "storyboard"].contains(filePath.path.extension),
                   !variantGroup.name!.hasSuffix(fileName)
                {
                    variantGroup.name = fileName
                    variantGroups[existingGroup.filePath] = nil
                    variantGroups[groupFilePath] = variantGroup
                }
            } else {
                isNew = true
                variantGroup = PBXVariantGroup(
                    children: [],
                    sourceTree: .group,
                    name: fileName
                )
                pbxProj.add(object: variantGroup)
                variantGroups[groupFilePath] = variantGroup
            }

            // Localized element
            let containedPath = Path(
                components: [
                    localizedContainerFilePath.path.lastComponent,
                    fileName,
                ]
            )
            let language = localizedContainerFilePath.path
                .lastComponentWithoutExtension

            let fileReference = PBXFileReference(
                sourceTree: .group,
                name: language,
                lastKnownFileType: filePath.path.lastKnownFileType,
                path: containedPath.string
            )
            pbxProj.add(object: fileReference)
            variantGroup.addChild(fileReference)

            // When a localized file is copied, we should grab the group instead
            variantGroups[filePath] = variantGroup

            knownRegions.insert(language)

            return (variantGroup, isNew)
        }

        func existingVariantGroup(
            containing filePath: FilePath
        ) -> (group: PBXVariantGroup, filePath: FilePath)? {
            let groupBaseFilePath = filePath.parent().parent()

            // Variant groups used to localize Interface Builder or Intent
            // Definition files (".xib", ".storyboard", or ".intentdefition")
            // can contain files of these, respectively, and corresponding
            // ".strings" files. However, the groups' names must always use the
            // extension of the main file, i.e. either ".xib" or ".storyboard".
            // Since the order in which such groups are formed is not
            // deterministic, we must check for existing groups having the same
            // name as the localized file and any of these extensions.
            if let fileExtension = filePath.path.extension,
               Self.localizedGroupExtensions.contains(fileExtension)
            {
                for groupExtension in Self.localizedGroupExtensions {
                    let groupFilePath = groupBaseFilePath + """
\(filePath.path.lastComponentWithoutExtension).\(groupExtension)
"""
                    if let variantGroup = variantGroups[groupFilePath] {
                        return (variantGroup, groupFilePath)
                    }
                }
            }

            let groupFilePath = groupBaseFilePath + filePath.path.lastComponent
            guard let variantGroup = variantGroups[groupFilePath] else {
                return nil
            }

            return (variantGroup, groupFilePath)
        }

        var externalGroup: PBXGroup?
        func createExternalGroup() -> PBXGroup {
            if let externalGroup = externalGroup {
                return externalGroup
            }

            let group = PBXGroup(
                sourceTree: .sourceRoot,
                name: "Bazel External Repositories",
                path: "../../external"
            )
            pbxProj.add(object: group)
            normalGroups[.external("")] = group
            externalGroup = group

            return group
        }

        var generatedGroup: PBXGroup?
        func createGeneratedGroup() -> PBXGroup {
            if let generatedGroup = generatedGroup {
                return generatedGroup
            }

            let group = PBXGroup(
                sourceTree: .sourceRoot,
                name: "Bazel Generated Files",
                path: "bazel-out"
            )
            pbxProj.add(object: group)
            normalGroups[.generated("")] = group
            generatedGroup = group

            return group
        }

        func isSpecialGroup(_ element: PBXFileElement) -> Bool {
            return element == externalGroup
                || element == generatedGroup
        }

        // Collect all files
        var createCompileStub = false
        var allInputPaths = extraFiles
        for target in targets.values {
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

        var rootElements: [PBXFileElement] = []
        var externalFileListFilePaths: [FilePath] = []
        var generatedFileListFilePaths: [FilePath] = []
        for fullFilePath in allInputPaths {
            var filePath: FilePath
            var lastElement: PBXFileElement?
            switch fullFilePath.type {
            case .project:
                filePath = .project(Path())
                lastElement = nil
            case .external:
                filePath = .external(Path())
                lastElement = createExternalGroup()
                externalFileListFilePaths.append(fullFilePath)
            case .generated:
                filePath = .generated(Path())
                lastElement = createGeneratedGroup()
                if !fullFilePath.isFolder {
                    generatedFileListFilePaths.append(fullFilePath)
                }
            }

            var coreDataContainer: XCVersionGroup?
            let components = fullFilePath.path.string.split(separator: "/")
            var parentIsLocalizedContainer = false
            for (offset, component) in components.enumerated() {
                let component = String(component)

                // swiftlint:disable:next shorthand_operator
                filePath = filePath + component
                let isLeaf = offset == components.count - 1
                filePath.isFolder = isLeaf && fullFilePath.isFolder
                if
                    let (element, isNew) = createElement(
                        in: pbxProj,
                        filePath: filePath,
                        pathComponent: component,
                        parentIsLocalizedContainer: parentIsLocalizedContainer,
                        isLeaf: isLeaf,
                        forceGroupCreation: fullFilePath.forceGroupCreation
                    )
                {
                    if isNew {
                        if let group = lastElement as? PBXGroup {
                            // This will be the case for all non-root elements
                            group.addChild(element)
                        } else if !isSpecialGroup(element) {
                            rootElements.append(element)
                        }

                        if let coreDataContainer = coreDataContainer {
                            // When a model file is copied, we should grab
                            // the group instead
                            xcVersionGroups[filePath] = coreDataContainer
                        }
                    }

                    if let element = element as? XCVersionGroup {
                        coreDataContainer = element
                    }

                    lastElement = element

                    // End early if we get back a file element. This can happen
                    // if a folder-like file is added.
                    if element is PBXFileReference { break }
                } else {
                    // TODO: Indicate this better
                    parentIsLocalizedContainer = true
                }
            }

            if let coreDataContainer = coreDataContainer {
                // When a model file is copied, we should grab
                // the group instead
                xcVersionGroups[fullFilePath] = coreDataContainer
            } else if fullFilePath != filePath {
                // We need to add extra entries for file-like folders, to allow
                // easy copying of resources
                guard let reference = lastElement as? PBXFileReference else {
                    throw PreconditionError(message: """
`lastElement` wasn't a `PBXFileReference`
""")
                }
                fileReferences[fullFilePath] = reference
            }
        }

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

        let externalPaths = externalFileListFilePaths
            .map { FilePathResolver.resolveExternal($0.path) }

        let generatedPaths = generatedFileListFilePaths
            .map { FilePathResolver.resolveGenerated($0.path) }

        var internalFiles: [Path: String] = [:]
        func addXCFileList(_ path: Path, paths: [String]) -> Bool {
            guard !paths.isEmpty else {
                return false
            }

            internalFiles[path] = Set(paths.map { "\($0)\n" }).sorted().joined()

            return true
        }

        let usesExternalFileList =
            addXCFileList(externalFileListPath, paths: externalPaths)
        let usesGeneratedFileList =
            addXCFileList(generatedFileListPath, paths: generatedPaths)

        // Handle special groups

        rootElements.sortGroupedLocalizedStandard()
        if let externalGroup = externalGroup {
            externalGroup.children.sortGroupedLocalizedStandard()
            rootElements.append(externalGroup)
        }
        if let generatedGroup = generatedGroup {
            generatedGroup.children.sortGroupedLocalizedStandard()
            rootElements.append(generatedGroup)
        }
        if let internalGroup = internalGroup {
            internalGroup.children.sortGroupedLocalizedStandard()
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
