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
        case .reference(let reference, _):
            return reference
        case .variantGroup(let group):
            return group
        case .xcVersionGroup(let group):
            return group
        }
    }
}

extension Generator {
    static let bazelForcedSwiftCompilePath: Path = "_BazelForcedCompile_.swift"
    static let compileStubPath: Path = "CompileStub.m"
    static let externalFileListPath: Path = "external.xcfilelist"
    static let generatedFileListPath: Path = "generated.xcfilelist"
    static let rsyncFileListPath: Path = "generated.rsynclist"
    static let appRsyncExcludeFileListPath: Path = "app.exclude.rsynclist"
    static let copiedGeneratedFileListPath: Path = "generated.copied.xcfilelist"
    static let modulemapsFileListPath: Path = "modulemaps.xcfilelist"
    static let fixedModulemapsFileListPath: Path = "modulemaps.fixed.xcfilelist"
    static let infoPlistsFileListPath: Path = "infoplists.xcfilelist"
    static let fixedInfoPlistsFileListPath: Path = "infoplists.fixed.xcfilelist"

    private static let localizedGroupExtensions: Set<String> = [
        "intentdefinition",
        "storyboard",
        "strings",
        "xib",
    ]

    // Most of the logic here is a modified version of
    // https://github.com/tuist/tuist/blob/a76be1d1df2ec912cbf5c4ba91a167fb1dfd0098/Sources/TuistGenerator/Generator/ProjectFileElements.swift
    static func createFilesAndGroups(
        in pbxProj: PBXProj,
        buildMode: BuildMode,
        targets: [TargetID: Target],
        extraFiles: Set<FilePath>,
        xccurrentversions: [XCCurrentVersion],
        filePathResolver: FilePathResolver,
        logger: Logger
    ) throws -> (
        files: [FilePath: File],
        rootElements: [PBXFileElement]
    ) {
        var elements: [FilePath: PBXFileElement] = [:]
        var knownRegions: Set<String> = []

        func createElement(
            in pbxProj: PBXProj,
            filePath: FilePath,
            pathComponent: String,
            isLeaf: Bool
        ) -> (PBXFileElement, isNew: Bool)? {
            if let element = elements[filePath] {
                return (element, false)
            }

            if filePath.path.isLocalizedContainer {
                // Localized container (e.g. /path/to/en.lproj)
                // We don't add it directly; an element will get added once the
                // next path component is evaluated.
                return nil
            } else if filePath.path.parent().isLocalizedContainer {
                // Localized file (e.g. /path/to/en.lproj/foo.png)
                return addLocalizedFile(filePath: filePath)
            } else if filePath.path.isCoreDataContainer {
                let group = XCVersionGroup(
                    path: pathComponent,
                    sourceTree: .group,
                    versionGroupType: filePath.path.versionGroupType
                )
                pbxProj.add(object: group)

                elements[filePath] = group

                return (group, true)
            } else if !(isLeaf || filePath.path.isFolderTypeFileSource) {
                let group = createGroup(
                    filePath: filePath,
                    pathComponent: pathComponent
                )
                return (group, true)
            } else {
                let lastKnownFileType: String?
                if filePath.isFolder {
                    lastKnownFileType = "folder"
                } else {
                    lastKnownFileType = filePath.path.lastKnownFileType
                }
                let file = PBXFileReference(
                    sourceTree: .group,
                    explicitFileType: filePath.path.explicitFileType,
                    lastKnownFileType: lastKnownFileType,
                    path: pathComponent
                )
                pbxProj.add(object: file)

                elements[filePath] = file

                return (file, true)
            }
        }

        func createGroup(
            filePath: FilePath,
            pathComponent: String
        ) -> PBXGroup {
            let group = PBXGroup(sourceTree: .group, path: pathComponent)
            pbxProj.add(object: group)
            elements[filePath] = group

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

            // Variant group
            let group: PBXVariantGroup
            let isNew: Bool
            if let existingGroup = existingVariantGroup(containing: filePath) {
                isNew = false
                group = existingGroup.group
                // For variant groups formed by Interface Builder files (".xib"
                // or ".storyboard") and corresponding ".strings" files, name
                // and path of the group must have the extension of the
                // Interface Builder file. Since the order in which such groups
                // are formed is not deterministic, we must change the name and
                // path here as necessary.
                if ["xib", "storyboard"].contains(filePath.path.extension),
                   !group.name!.hasSuffix(fileName)
                {
                    group.name = fileName
                    elements[existingGroup.filePath] = nil
                    elements[groupFilePath] = group
                }
            } else {
                isNew = true
                group = PBXVariantGroup(
                    children: [],
                    sourceTree: .group,
                    name: fileName
                )
                pbxProj.add(object: group)
                elements[groupFilePath] = group
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
            group.addChild(fileReference)

            // When a localized file is copied, we should grab the group instead
            elements[filePath] = group

            knownRegions.insert(language)

            return (group, isNew)
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
                    if let group = elements[groupFilePath] as? PBXVariantGroup {
                        return (group, groupFilePath)
                    }
                }
            }

            let groupFilePath = groupBaseFilePath + filePath.path.lastComponent
            guard let group = elements[groupFilePath] as? PBXVariantGroup else {
                return nil
            }

            return (group, groupFilePath)
        }

        var externalGroup: PBXGroup?
        func createExternalGroup() -> PBXGroup {
            if let externalGroup = externalGroup {
                return externalGroup
            }

            let group = PBXGroup(
                sourceTree: .group,
                name: "Bazel External Repositories",
                path: (filePathResolver.internalDirectory + "links/external")
                    .string
            )
            pbxProj.add(object: group)
            elements[.external("")] = group
            externalGroup = group

            return group
        }

        var generatedGroup: PBXGroup?
        func createGeneratedGroup() -> PBXGroup {
            if let generatedGroup = generatedGroup {
                return generatedGroup
            }

            let group = PBXGroup(
                sourceTree: .group,
                name: "Bazel Generated Files",
                path: (filePathResolver.internalDirectory + "links/gen_dir")
                    .string
            )
            pbxProj.add(object: group)
            elements[.generated("")] = group
            generatedGroup = group

            return group
        }

        var internalGroup: PBXGroup?
        func createInternalGroup() -> PBXGroup {
            if let internalGroup = internalGroup {
                return internalGroup
            }

            let group = PBXGroup(
                sourceTree: .group,
                name: filePathResolver.internalDirectoryName,
                path: filePathResolver.internalDirectory.string
            )
            pbxProj.add(object: group)
            elements[.internal("")] = group
            internalGroup = group

            return group
        }

        func isSpecialGroup(_ element: PBXFileElement) -> Bool {
            return element == externalGroup
                || element == generatedGroup
                || element == internalGroup
        }

        // Collect all files
        var allInputPaths = extraFiles
        for target in targets.values {
            allInputPaths.formUnion(target.inputs.all)
            // We use .nonGenerated instead of .all because generated files will 
            // be collected via product outputs, or `extraFiles`
            allInputPaths.formUnion(target.linkerInputs.nonGenerated)
            allInputPaths.formUnion(
                target.outputs.forcedBazelCompileFiles(buildMode: buildMode)
            )
            if !target.inputs.containsSources
                && target.product.type != .bundle
            {
                allInputPaths.insert(.internal(compileStubPath))
            }
        }

        var rootElements: [PBXFileElement] = []
        var nonDirectFolderLikeFilePaths: Set<FilePath> = []
        var nonIncludedFiles: Set<FilePath> = []
        for fullFilePath in allInputPaths {
            guard fullFilePath.includeInNavigator else {
                nonIncludedFiles.insert(fullFilePath)
                continue
            }

            var filePath: FilePath
            var lastElement: PBXFileElement?
            switch fullFilePath.type {
            case .project:
                filePath = .project(Path())
                lastElement = nil
            case .external:
                filePath = .external(Path())
                lastElement = createExternalGroup()
            case .generated:
                filePath = .generated(Path())
                lastElement = createGeneratedGroup()
            case .internal:
                filePath = .internal(Path())
                lastElement = createInternalGroup()
            }

            var coreDataContainer: XCVersionGroup?
            let components = fullFilePath.path.components
            for (offset, component) in components.enumerated() {
                filePath = filePath + component
                let isLeaf = offset == components.count - 1
                filePath.isFolder = isLeaf && fullFilePath.isFolder
                if
                    let (element, isNew) = createElement(
                        in: pbxProj,
                        filePath: filePath,
                        pathComponent: component,
                        isLeaf: isLeaf
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
                            elements[filePath] = coreDataContainer
                        }
                    }

                    if let element = element as? XCVersionGroup {
                        coreDataContainer = element
                    }

                    lastElement = element

                    // End early if we get back a file element. This can happen
                    // if a folder-like file is added.
                    if element is PBXFileReference { break }
                }
            }

            if let coreDataContainer = coreDataContainer {
                // When a model file is copied, we should grab
                // the group instead
                elements[fullFilePath] = coreDataContainer
            } else if fullFilePath != filePath {
                // We need to add extra entries for file-like folders, to allow
                // easy copying of resources
                elements[fullFilePath] = lastElement
                nonDirectFolderLikeFilePaths.insert(filePath)
            }
        }

        // Fix sourceTree of `bazelForcedSwiftCompilePath`
        if let element = elements[.internal(bazelForcedSwiftCompilePath)] {
            element.sourceTree = .custom("DERIVED_FILE_DIR")
        }

        try setXCCurrentVersions(
            elements: elements,
            xccurrentversions: xccurrentversions,
            logger: logger
        )

        var files: [FilePath: File] = [:]
        for (filePath, element) in elements {
            if let reference = element as? PBXFileReference {
                if filePath == .internal(compileStubPath) {
                    files[filePath] = .reference(reference, content: "")
                } else {
                    files[filePath] = .reference(reference)
                }
            } else if let variantGroup = element as? PBXVariantGroup {
                files[filePath] = .variantGroup(variantGroup)
            } else if let xcVersionGroup = element as? XCVersionGroup {
                files[filePath] = .xcVersionGroup(xcVersionGroup)
            }
        }

        // Write xcfilelists

        let fileListElements = elements.filter { filePath, _ in
            return !nonDirectFolderLikeFilePaths.contains(filePath)
        }

        let externalPaths = try fileListElements
            .filter { filePath, element in
                return filePath.type == .external
                    && element is PBXFileReference
            }
            .map { filePath, _ in try filePathResolver.resolve(filePath) }

        let generatedFilePaths = fileListElements
            .filter { filePath, element in
                return filePath.type == .generated
                    && !filePath.isFolder
                    && element is PBXFileReference
            }
            .map { filePath, _ in filePath } + nonIncludedFiles

        let generatedPaths = try generatedFilePaths.map { filePath in
            return try filePathResolver.resolve(
                filePath,
                useOriginalGeneratedFiles: true
            )
        }
        let rsyncPaths = generatedFilePaths.map { $0.path }
        let copiedGeneratedPaths = try generatedFilePaths.map { filePath in
            // We need to use `$(GEN_DIR)` instead of `$(BUILD_DIR)` here to
            // match the project navigator. This is only needed for files
            // referenced by `PBXBuildFile` or have specific build settings.
            return try filePathResolver.resolve(filePath, useGenDir: true)
        }
        let modulemapPaths = try generatedFilePaths
            .filter { $0.path.extension == "modulemap" }
            .map { try filePathResolver.resolve($0) }
        let fixedModulemapPaths = modulemapPaths.map { path in
            return path.replacingExtension("xcode.modulemap")
        }
        let infoPlistPaths = try generatedFilePaths
            .filter { $0.path.lastComponent == "Info.plist" }
            .map { filePath in
                // We need to use `$(GEN_DIR)` instead of `$(BUILD_DIR)` here to
                // match the project navigator. This is only needed for files
                // referenced by `PBXBuildFile` or have specific build settings.
                return try filePathResolver.resolve(filePath, useGenDir: true)
            }
        let fixedInfoPlistPaths = infoPlistPaths.map { path in
            return path.replacingExtension("xcode.plist")
        }

        if buildMode.usesBazelModeBuildScripts &&
            targets.contains(where: { $1.product.type.isApplication })
        {
            files[.internal(appRsyncExcludeFileListPath)] =
                .nonReferencedContent(#"""
/*.app/Frameworks/libXCTestBundleInject.dylib
/*.app/Frameworks/libXCTestSwiftSupport.dylib
/*.app/Frameworks/XCTAutomationSupport.framework
/*.app/Frameworks/XCTest.framework
/*.app/Frameworks/XCTestCore.framework
/*.app/Frameworks/XCUIAutomation.framework
/*.app/Frameworks/XCUnit.framework
/*.app/PlugIns

"""#)
        }

        func addXCFileList(_ path: Path, paths: [Path]) {
            guard !paths.isEmpty else {
                return
            }

            files[.internal(path)] = .nonReferencedContent(
                Set(paths.map { "\($0)\n" }).sortedLocalizedStandard().joined()
            )
        }

        addXCFileList(externalFileListPath, paths: externalPaths)
        addXCFileList(generatedFileListPath, paths: generatedPaths)
        addXCFileList(rsyncFileListPath, paths: rsyncPaths)
        addXCFileList(copiedGeneratedFileListPath, paths: copiedGeneratedPaths)
        addXCFileList(modulemapsFileListPath, paths: modulemapPaths)
        addXCFileList(fixedModulemapsFileListPath, paths: fixedModulemapPaths)
        addXCFileList(infoPlistsFileListPath, paths: infoPlistPaths)
        addXCFileList(fixedInfoPlistsFileListPath, paths: fixedInfoPlistPaths)

        // Write LinkFileLists
        
        for target in targets.values {
            let linkFiles = try target.linkerInputs.staticLibraries
                .map { filePath in
                    return """
\(try filePathResolver.resolve(filePath, useGenDir: true, mode: .srcRoot))

"""
                }
            if !linkFiles.isEmpty {
                files[try target.linkFileListFilePath()] =
                    .nonReferencedContent(linkFiles.joined())
            }
        }

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

        return (files, rootElements)
    }

    private static func setXCCurrentVersions(
        elements: [FilePath: PBXFileElement],
        xccurrentversions: [XCCurrentVersion],
        logger: Logger
    ) throws {
        for xccurrentversion in xccurrentversions {
            guard let element = elements[xccurrentversion.container] else {
                throw PreconditionError(message: """
"\(xccurrentversion.container.path)" `XCVersionGroup` not found in `elements`
""")
            }

            guard let container = element as? XCVersionGroup else {
                throw PreconditionError(message: """
"\(xccurrentversion.container.path)" isn't an `XCVersionGroup`
""")
            }

            guard
                let versionChild = container.children
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

            container.currentVersion = versionFile
        }
    }
}

private extension Inputs {
    var containsSources: Bool { !srcs.isEmpty || !nonArcSrcs.isEmpty }
}

private extension Outputs {
    func forcedBazelCompileFiles(buildMode: BuildMode) -> Set<FilePath> {
        if buildMode.usesBazelModeBuildScripts && swift != nil {
            return [.internal(Generator.bazelForcedSwiftCompilePath)]
        }

        return []
    }
}

private extension Path {
    var sourceTree: PBXSourceTree { isAbsolute ? .absolute : .group }
}

extension Sequence where Element == FilePath {
    var containsExternalFiles: Bool { contains { $0.type == .external } }
    var containsGeneratedFiles: Bool { contains { $0.type == .generated } }
}

extension Dictionary where Key == FilePath {
    var containsExternalFiles: Bool { keys.containsExternalFiles }
    var containsGeneratedFiles: Bool { keys.containsGeneratedFiles }
}
