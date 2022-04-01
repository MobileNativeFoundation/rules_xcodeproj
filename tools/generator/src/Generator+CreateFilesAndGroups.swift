import PathKit
import XcodeProj

/// Wrapper for `PBXFileReference`, adding additional associated data.
struct File: Equatable {
    let reference: PBXFileReference?

    /// File content to be written to disk.
    ///
    /// This is only used by the `FilePath.PathType.internal` files.
    let content: String

    init(reference: PBXFileReference?, content: String = "") {
        self.reference = reference
        self.content = content
    }
}

extension Generator {
    static let compileStubPath: Path = "CompileStub.swift"
    static let generatedFileListPath: Path = "generated.xcfilelist"

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

        func createElement(
            in pbxProj: PBXProj,
            filePath: FilePath,
            pathComponent: String,
            isLeaf: Bool
        ) -> (PBXFileElement, isNew: Bool) {
            if let element = elements[filePath] {
                return (element, false)
            }

            // TODO: Handle localized files
            // TODO: Handle CoreData models
            if !(isLeaf || Path(pathComponent).isFolderTypeFileSource) {
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
                    lastKnownFileType = Path(pathComponent).lastKnownFileType
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
                let (element, isNew) = createElement(
                    in: pbxProj,
                    filePath: filePath,
                    pathComponent: component,
                    isLeaf: isLeaf
                )
                if isNew {
                    if let group = lastElement as? PBXGroup {
                        // This will be the case for all non-root elements
                        group.addChild(element)
                    } else if !isSpecialGroup(element) {
                        rootElements.append(element)
                    }
                }

                lastElement = element

                // End early if we get back a file element. This can happen if
                // a folder-like file is added.
                if element is PBXFileReference { break }
            }

            if fullFilePath != filePath {
                // We need to add extra entries for file-like folders, to allow
                // easy copying of resources
                elements[fullFilePath] = lastElement
            }
        }

        var files: [FilePath: File] = [:]
        for (filePath, element) in elements {
            guard let reference = element as? PBXFileReference else {
                continue
            }

            files[filePath] = File(reference: reference)
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

            files[.internal(generatedFileListPath)] = File(
                reference: reference,
                content: Set(generatedFiles).sortedLocalizedStandard().joined()
            )
        }

        // Write LinkFileLists
        
        for target in targets.values {
            let linkFiles = target.links.map { "\($0)\n" }
            if !linkFiles.isEmpty {
                files[try target.linkFileListFilePath()] = File(
                    reference: nil,
                    content: Set(linkFiles).sortedLocalizedStandard().joined()
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
