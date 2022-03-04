import PathKit
import XcodeProj

extension Generator {
    static let compileStubPath = Path("CompileStub.swift")

    static func createFilesAndGroups(
        in pbxProj: PBXProj,
        targets: [TargetID: Target],
        extraFiles: Set<Path>,
        externalDirectory: Path,
        internalDirectoryName: String,
        workspaceOutputPath: Path
    ) -> (
        elements: [FilePath: PBXFileElement],
        rootElements: [PBXFileElement]
    ) {
        var elements: [FilePath: PBXFileElement] = [:]

        var externalGroup: PBXGroup?
        func createGroup(
            filePath: FilePath,
            pathComponent: String
        ) -> PBXGroup {
            let group: PBXGroup
            // TODO: Handle in-workspace "external/" paths
            if filePath == .input("external") {
                group = PBXGroup(
                    sourceTree: externalDirectory.sourceTree,
                    name: "Bazel External Repositories",
                    path: externalDirectory.string
                )
                externalGroup = group
            } else {
                group = PBXGroup(sourceTree: .group, path: pathComponent)
            }

            pbxProj.add(object: group)
            elements[filePath] = group

            return group
        }

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
                let file = PBXFileReference(
                    sourceTree: .group,
                    lastKnownFileType: Path(pathComponent).lastKnownFileType,
                    path: pathComponent
                )
                pbxProj.add(object: file)
                elements[filePath] = file
                return (file, true)
            }
        }

        var internalGroup: PBXGroup?
        func createInternalGroup() -> PBXGroup {
            if let internalGroup = internalGroup {
                return internalGroup
            }

            let group = PBXGroup(
                sourceTree: .group,
                name: internalDirectoryName,
                path: (workspaceOutputPath + internalDirectoryName).string
            )
            pbxProj.add(object: group)
            elements[.internal("")] = group
            internalGroup = group

            return group
        }

        // Collect all files
        var allInputPaths = Set(extraFiles.map(FilePath.input))
        for target in targets.values {
            if target.srcs.isEmpty {
                allInputPaths.insert(.internal(compileStubPath))
            } else {
                allInputPaths.formUnion(Set(target.srcs.map(FilePath.input)))
            }
        }

        var rootElements: [PBXFileElement] = []
        for fullFilePath in allInputPaths {
            let fullPath: Path
            var filePath: FilePath
            var lastElement: PBXFileElement?
            switch fullFilePath {
            case .input(let path):
                fullPath = path
                filePath = .input(Path())
                lastElement = nil
            case .internal(let path):
                fullPath = path
                filePath = .internal(Path())
                lastElement = createInternalGroup()
            }

            let components = fullPath.components
            for (offset, component) in components.enumerated() {
                filePath = filePath + component
                let (element, isNew) = createElement(
                    in: pbxProj,
                    filePath: filePath,
                    pathComponent: component,
                    isLeaf: offset == components.count - 1
                )
                if isNew {
                    if let group = lastElement as? PBXGroup {
                        // This will be the case for all non-root elements
                        group.addChild(element)
                    } else if element != externalGroup {
                        rootElements.append(element)
                    }
                }

                // End early if we get back a file element. This can happen if
                // a folder-like file is added.
                if element is PBXFileReference { break }
                lastElement = element
            }
        }

        // Handle internal

        rootElements.sortGroupedLocalizedStandard()
        if let externalGroup = externalGroup {
            externalGroup.children.sortGroupedLocalizedStandard()
            rootElements.append(externalGroup)
        }
        if let internalGroup = internalGroup {
            internalGroup.children.sortGroupedLocalizedStandard()
            rootElements.append(internalGroup)
        }

        return (elements, rootElements)
    }
}

enum FilePath: Hashable {
    case input(Path)
    case `internal`(Path)
}

func +(lhs: FilePath, rhs: String) -> FilePath {
    switch lhs {
    case .input(let path):
        return .input(path + rhs)
    case .internal(let path):
        return .internal(path + rhs)
    }
}

private extension Path {
    var sourceTree: PBXSourceTree { isAbsolute ? .absolute : .group }
}
