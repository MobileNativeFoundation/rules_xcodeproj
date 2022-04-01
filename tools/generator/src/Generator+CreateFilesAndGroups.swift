import PathKit
import XcodeProj

/// Wrapper for files (`PBXFileReference` and `PBXVariantGroup`), adding
/// additional associated data.
enum File: Equatable {
    case reference(PBXFileReference?, content: String)
    case variantGroup(PBXVariantGroup)
}

extension File {
    static func reference(_ reference: PBXFileReference) -> File {
        return .reference(reference, content: "")
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
        }
    }
}

extension Generator {
    static let compileStubPath: Path = "CompileStub.swift"
    static let generatedFileListPath: Path = "generated.xcfilelist"

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
        targets: [TargetID: Target],
        extraFiles: Set<FilePath>,
        filePathResolver: FilePathResolver
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

            // TODO: Handle CoreData models

            if filePath.path.isLocalizedContainer {
                // Localized container (e.g. /path/to/en.lproj)
                // We don't add it directly; an element will get added once the
                // next path component is evaluated.
                return nil
            } else if filePath.path.parent().isLocalizedContainer {
                // Localized file (e.g. /path/to/en.lproj/foo.png)
                return addLocalizedFile(filePath: filePath)
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
                sourceTree: filePathResolver.externalDirectory.sourceTree,
                name: "Bazel External Repositories",
                path: filePathResolver.externalDirectory.string
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
                sourceTree: filePathResolver.generatedDirectory.sourceTree,
                name: "Bazel Generated Files",
                path: filePathResolver.generatedDirectory.string
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
            if !target.inputs.containsSources
                && target.product.type != .bundle
            {
                allInputPaths.insert(.internal(compileStubPath))
            }
        }

        var rootElements: [PBXFileElement] = []
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
            case .generated:
                filePath = .generated(Path())
                lastElement = createGeneratedGroup()
            case .internal:
                filePath = .internal(Path())
                lastElement = createInternalGroup()
            }

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
                    }

                    lastElement = element

                    // End early if we get back a file element. This can happen
                    // if a folder-like file is added.
                    if element is PBXFileReference { break }
                }
            }

            if fullFilePath != filePath {
                // We need to add extra entries for file-like folders, to allow
                // easy copying of resources
                elements[fullFilePath] = lastElement
            }
        }

        var files: [FilePath: File] = [:]
        for (filePath, element) in elements {
            if let reference = element as? PBXFileReference {
                files[filePath] = .reference(reference)
            } else if let variantGroup = element as? PBXVariantGroup {
                files[filePath] = .variantGroup(variantGroup)
            }
        }

        // Write generated.xcfilelist

        let generatedFiles = elements
            .filter { filePath, element in
                return filePath.type == .generated
                    && element is PBXFileReference
            }
            .map { "\($1.projectRelativePath(in: pbxProj))\n" }

        if !generatedFiles.isEmpty {
            let reference = PBXFileReference(
                sourceTree: .group,
                lastKnownFileType: generatedFileListPath.lastKnownFileType,
                path: generatedFileListPath.string
            )
            pbxProj.add(object: reference)
            createInternalGroup().addChild(reference)

            files[.internal(generatedFileListPath)] = .reference(
                reference,
                content: Set(generatedFiles).sortedLocalizedStandard().joined()
            )
        }

        // Write LinkFileLists
        
        for target in targets.values {
            let linkFiles = target.links.map { "\($0)\n" }
            if !linkFiles.isEmpty {
                files[try target.linkFileListFilePath()] =
                    .nonReferencedContent(
                        Set(linkFiles).sortedLocalizedStandard().joined()
                    )
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
}

private extension Inputs {
    var containsSources: Bool { !srcs.isEmpty || !nonArcSrcs.isEmpty }
}

private extension Path {
    var sourceTree: PBXSourceTree { isAbsolute ? .absolute : .group }
}

extension PBXFileElement {
    func projectRelativePath(in pbxProj: PBXProj) -> Path {
        switch sourceTree {
        case .absolute?:
            return Path(path!)
        case .group?:
            guard let group = parent else {
                return Path(path ?? "")
            }
            return group.projectRelativePath(in: pbxProj) + path!
        default:
            preconditionFailure("""
Unexpected sourceTree: \(sourceTree?.description ?? "nil")
""")
        }
    }
}

extension Sequence where Element == FilePath {
    var containsGeneratedFiles: Bool { contains { $0.type == .generated } }
}

extension Dictionary where Key == FilePath {
    var containsGeneratedFiles: Bool { keys.containsGeneratedFiles }
}
