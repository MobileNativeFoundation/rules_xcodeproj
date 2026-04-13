import PBXProj

extension Generator {
    static func calculatePathTree(
        paths: [BazelPath],
        generatedPaths: [GeneratedPath],
        synchronizedFolders: [SynchronizedFolderTarget]
    ) -> [PathTreeNode] {
        let activeSynchronizedFolders = visibleSynchronizedFolders(
            synchronizedFolders
        )
        let synchronizedFolderPaths = activeSynchronizedFolders.map(\.path)

        /// `[package: [config: [path]]`
        var generatedPathsByPackageAndConfig:
            [BazelPath: [String: [BazelPath]]] = [:]
        for generatedPath in generatedPaths {
            let package: BazelPath
            let path: BazelPath

            if let synchronizedFolderPath = synchronizedFolderPaths
                .filter({
                    isPathDescendant(generatedPath.package.path, of: $0.path)
                })
                .max(by: { lhs, rhs in
                    lhs.path.count < rhs.path.count
                })
            {
                package = parentFolder(of: synchronizedFolderPath)

                let folderRelativePackagePath = relativePath(
                    from: package.path,
                    to: generatedPath.package.path
                )
                if folderRelativePackagePath.isEmpty {
                    path = generatedPath.path
                } else {
                    path = BazelPath(
                        "\(folderRelativePackagePath)/\(generatedPath.path.path)"
                    )
                }
            } else {
                package = generatedPath.package
                path = generatedPath.path
            }

            generatedPathsByPackageAndConfig[
                package,
                default: [:]
            ][generatedPath.config, default: []].append(path)
        }

        // FIXME: Do this in parallel
        var generatedFiles:
            [(package: BazelPath, generatedFiles: PathTreeNode.GeneratedFiles)]
                = []
        for (package, pathsByConfig) in generatedPathsByPackageAndConfig {
            if pathsByConfig.count == 1 {
                let (config, paths) = pathsByConfig.first!

                let path: String
                if package.path.isEmpty {
                    path = "\(config)/bin"
                } else {
                    path = "\(config)/bin/\(package.path)"
                }

                generatedFiles.append(
                    (
                        package,
                        .singleConfig(
                            path: path,
                            children: calculateRootedPathTree(paths: paths)
                        )
                    )
                )
            } else {
                let packageBin: String
                if package.path.isEmpty {
                    packageBin = "bin"
                } else {
                    packageBin = "bin/\(package.path)"
                }

                generatedFiles.append(
                    (
                        package,
                        .multipleConfigs(
                            pathsByConfig.sorted { $0.key < $1.key }.map({ config, paths in
                                return .init(
                                    name: config,
                                    path: "\(config)/\(packageBin)",
                                    children:
                                        calculateRootedPathTree(paths: paths)
                                )
                            })
                        )
                    )
                )
            }
        }

        return calculateRootedPathTree(
            paths: paths.filter { path in
                !synchronizedFolderPaths.contains { folderPath in
                    isPathDescendant(path.path, of: folderPath.path)
                }
            },
            synchronizedFolders: activeSynchronizedFolders,
            generatedFiles: generatedFiles
        )
    }

    private static func calculateRootedPathTree(
        paths: [BazelPath],
        synchronizedFolders: [PathTreeNode.SynchronizedFolder] = [],
        generatedFiles: [
            (package: BazelPath, generatedFiles: PathTreeNode.GeneratedFiles)
        ] = []
    ) -> [PathTreeNode] {
        guard
            !paths.isEmpty ||
            !synchronizedFolders.isEmpty ||
            !generatedFiles.isEmpty
        else {
            return []
        }

        var nodesByComponentCount: [Int: [PathTreeNodeToVisit]] = [:]
        for path in paths {
            let components = path.path.split(separator: "/")
            nodesByComponentCount[components.count, default: []]
                .append(
                    PathTreeNodeToVisit(
                      components: components,
                      kind: .file
                  )
                )
        }

        for synchronizedFolder in synchronizedFolders {
            let components = synchronizedFolder.path.path.split(separator: "/")
            nodesByComponentCount[components.count, default: []]
                .append(
                    PathTreeNodeToVisit(
                        components: components,
                        kind: .synchronizedGroup(synchronizedFolder)
                    )
                )
        }

        for (`package`, generatedFiles) in generatedFiles {
            var components = `package`.path.split(separator: "/")
            components.append("")
            nodesByComponentCount[components.count, default: []]
                .append(
                    PathTreeNodeToVisit(
                        components: components,
                        kind: .generatedFiles(generatedFiles)
                    )
                )
        }

        for componentCount in (1...nodesByComponentCount.keys.max()!)
            .reversed()
        {
            let nodesToVisit = nodesByComponentCount
                .removeValue(forKey: componentCount)!

            let sortedNodesToVisit = nodesToVisit.sorted { lhs, rhs in
                // Already bucketed to have the same component count, so we
                // don't sort on count first

                for i in lhs.components.indices {
                   let lhsComponent = lhs.components[i]
                   let rhsComponent = rhs.components[i]
                   guard lhsComponent == rhsComponent else {
                       // We properly sort in `CreateGroupChildElements`, so we
                       // do a simple version here
                       return lhsComponent < rhsComponent
                   }
                }

                return false
            }

            // Create parent nodes

            let firstNode = sortedNodesToVisit[0]
            var collectedParentComponents = firstNode.components.dropLast(1)
            var collectedChildren: [PathTreeNode] = []
            var additionalNodesToVisitForNextComponentCount:
                [PathTreeNodeToVisit] = []

            for nodeToVisit in sortedNodesToVisit {
                let parentComponents = nodeToVisit.components.dropLast(1)
                if parentComponents != collectedParentComponents {
                    additionalNodesToVisitForNextComponentCount.append(
                        PathTreeNodeToVisit(
                            components: Array(collectedParentComponents),
                            kind: .group(children: collectedChildren)
                        )
                    )

                    collectedParentComponents = parentComponents
                    collectedChildren = []
                }

                let node: PathTreeNode
                switch nodeToVisit.kind {
                case .file:
                    node = .file(String(nodeToVisit.components.last!))
                case .group(let children):
                    node = .group(
                        name: String(nodeToVisit.components.last!),
                        children: children
                    )
                case .generatedFiles(let generatedFiles):
                    node = .generatedFiles(generatedFiles)
                case .synchronizedGroup(let synchronizedFolder):
                    node = .synchronizedGroup(
                        name: String(nodeToVisit.components.last!),
                        synchronizedFolder: synchronizedFolder
                    )
                }
                collectedChildren.append(node)
            }

            guard componentCount != 1 else {
                // Root
                return collectedChildren
            }

            // Last node
            additionalNodesToVisitForNextComponentCount.append(
                PathTreeNodeToVisit(
                    components: Array(collectedParentComponents),
                    kind: .group(children: collectedChildren)
                )
            )

            nodesByComponentCount[componentCount - 1, default: []]
                .append(contentsOf: additionalNodesToVisitForNextComponentCount)
        }

        // This is unreachable because of the guard in the the `for` loop above.
        // We iterate down to `1`, and the guard catches on `1`.
        fatalError()
    }
}

enum PathTreeNode: Equatable {
    struct SynchronizedFolder: Equatable {
        let path: BazelPath
        let targets: [SynchronizedFolderTarget]
    }

    enum GeneratedFiles: Equatable {
        struct Config: Equatable {
            let name: String
            let path: String
            let children: [PathTreeNode]
        }

        case singleConfig(path: String, children: [PathTreeNode])
        case multipleConfigs(_ configs: [Config])
    }

    case file(String)
    case group(name: String, children: [PathTreeNode])
    case generatedFiles(GeneratedFiles)
    case synchronizedGroup(name: String, synchronizedFolder: SynchronizedFolder)
}

extension PathTreeNode {
    var nameForSpecialGroupChild: String {
        switch self {
        case .file(let name):
            return name
        case .group(let name, _):
            return name
        case .generatedFiles:
            // This is only called from `CreateVerisonGroup` and
            // `CreateLocalizedFiles` where this case can't be hit
            fatalError()
        case .synchronizedGroup(let name, _):
            return name
        }
    }
}

private class PathTreeNodeToVisit {
    enum Kind: Equatable {
        case file
        case group(children: [PathTreeNode])
        case generatedFiles(PathTreeNode.GeneratedFiles)
        case synchronizedGroup(PathTreeNode.SynchronizedFolder)
    }

    let components: [String.SubSequence]
    let kind: Kind

    init(
        components: [String.SubSequence],
        kind: Kind
    ) {
        self.components = components
        self.kind = kind
    }
}

private func visibleSynchronizedFolders(
    _ synchronizedFolders: [SynchronizedFolderTarget]
) -> [PathTreeNode.SynchronizedFolder] {
    let exactFolders = groupedSynchronizedFolders(synchronizedFolders)
    let topLevelExactFolders = exactFolders.filter { folder in
        !exactFolders.contains { candidate in
            candidate.path != folder.path &&
                isPathDescendant(folder.path.path, of: candidate.path.path)
        }
    }

    let promotedFolders = Dictionary(
        grouping: topLevelExactFolders.compactMap { folder -> (String, String)? in
            let components = folder.path.path.split(separator: "/")
            guard components.count >= 3 else {
                return nil
            }

            return (
                components.prefix(2).joined(separator: "/"),
                String(components[2])
            )
        },
        by: \.0
    ).compactMap { path, descendants -> PathTreeNode.SynchronizedFolder? in
        let distinctThirdComponents = Set(descendants.map(\.1))
        guard distinctThirdComponents.count > 1 else {
            return nil
        }

        return .init(
            path: BazelPath(path),
            targets: []
        )
    }

    let promotedPaths = Set(promotedFolders.map(\.path.path))
    return (
        topLevelExactFolders.filter { folder in
            !promotedPaths.contains { path in
                isPathDescendant(folder.path.path, of: path)
            }
        } +
        promotedFolders
    ).sorted { lhs, rhs in
        lhs.path < rhs.path
    }
}

private func parentFolder(of path: BazelPath) -> BazelPath {
    guard let lastSlashIndex = path.path.lastIndex(of: "/") else {
        return BazelPath("")
    }

    return BazelPath(String(path.path[..<lastSlashIndex]))
}

private func relativePath(from base: String, to path: String) -> String {
    guard !base.isEmpty else {
        return path
    }
    guard path != base else {
        return ""
    }

    return String(path.dropFirst(base.count + 1))
}
