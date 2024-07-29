import PBXProj

extension Generator {
    static func calculatePathTree(
        paths: [BazelPath],
        generatedPaths: [GeneratedPath]
    ) -> [PathTreeNode] {
        /// `[package: [config: [path]]`
        var generatedPathsByPackageAndConfig:
            [BazelPath: [String: [BazelPath]]] = [:]
        for generatedPath in generatedPaths {
            generatedPathsByPackageAndConfig[
                generatedPath.package,
                default: [:]
            ][generatedPath.config, default: []].append(generatedPath.path)
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
            paths: paths,
            generatedFiles: generatedFiles
        )
    }

    private static func calculateRootedPathTree(
        paths: [BazelPath],
        generatedFiles: [
            (package: BazelPath, generatedFiles: PathTreeNode.GeneratedFiles)
        ] = []
    ) -> [PathTreeNode] {
        guard !paths.isEmpty else {
            return []
        }

        var nodesByComponentCount: [Int: [PathTreeNodeToVisit]] = [:]
        for path in paths {
            let components = path.path.split(separator: "/")
            nodesByComponentCount[components.count, default: []]
                .append(
                    PathTreeNodeToVisit(
                      components: components,
                      kind: .file(isFolder: path.isFolder)
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

                guard lhs.kind == rhs.kind else {
                    if case let .file(isFolder) = lhs.kind {
                        // Folders should appear before non-folders, because
                        // when we sort in `CreateGroupChildElements` it will
                        // see folders and groups with the same name as the
                        // same, but will leave in-place any sorting we do here
                        return isFolder
                    }

                    return false
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
                case .file(let isFolder):
                    node = .file(
                        name: String(nodeToVisit.components.last!),
                        isFolder: isFolder
                    )
                case .group(let children):
                    node = .group(
                        name: String(nodeToVisit.components.last!),
                        children: children
                    )
                case .generatedFiles(let generatedFiles):
                    node = .generatedFiles(generatedFiles)
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
    enum GeneratedFiles: Equatable {
        struct Config: Equatable {
            let name: String
            let path: String
            let children: [PathTreeNode]
        }

        case singleConfig(path: String, children: [PathTreeNode])
        case multipleConfigs(_ configs: [Config])
    }

    case file(name: String, isFolder: Bool)
    case group(name: String, children: [PathTreeNode])
    case generatedFiles(GeneratedFiles)
}

extension PathTreeNode {
    var nameForSpecialGroupChild: String {
        switch self {
        case .file(let name, _):
            return name
        case .group(let name, _):
            return name
        case .generatedFiles(_):
            // This is only called from `CreateVerisonGroup` and
            // `CreateLocalizedFiles` where this case can't be hit
            fatalError()
        }
    }
}

private class PathTreeNodeToVisit {
    enum Kind: Equatable {
        case file(isFolder: Bool)
        case group(children: [PathTreeNode])
        case generatedFiles(PathTreeNode.GeneratedFiles)
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
