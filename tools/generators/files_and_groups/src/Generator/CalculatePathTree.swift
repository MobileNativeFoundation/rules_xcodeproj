import PBXProj

extension Generator {
    static func calculatePathTree(paths: Set<BazelPath>) -> PathTreeNode.Group {
        guard !paths.isEmpty else {
            return PathTreeNode.Group(children: [])
        }

        var nodesByComponentCount: [Int: [PathTreeNodeToVisit]] = [:]
        for path in paths {
            let components = path.path.split(separator: "/")
            nodesByComponentCount[components.count, default: []]
                .append(
                    PathTreeNodeToVisit(
                      components: components,
                      isFolder: path.isFolder,
                      children: []
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

                guard lhs.isFolder == rhs.isFolder else {
                    return lhs.isFolder
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
                            children: collectedChildren
                        )
                    )

                    collectedParentComponents = parentComponents
                    collectedChildren = []
                }

                let nodeKind = if nodeToVisit.children.isEmpty {
                    PathTreeNode.Kind.file(isFolder: nodeToVisit.isFolder)
                } else {
                    PathTreeNode.Kind.group(children: nodeToVisit.children)
                }

                collectedChildren.append(
                    PathTreeNode(
                        name: String(nodeToVisit.components.last!),
                        kind: nodeKind
                    )
                )
            }

            guard componentCount != 1 else {
                // Root node
                return PathTreeNode.Group(children: collectedChildren)
            }

            // Last node
            additionalNodesToVisitForNextComponentCount.append(
                PathTreeNodeToVisit(
                    components: Array(collectedParentComponents),
                    children: collectedChildren
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

// A class for performance reasons.
class PathTreeNode {
    struct Group: Equatable {
        let children: [PathTreeNode]
    }

    enum Kind: Equatable {
        case file(isFolder: Bool)
        case group(Group)
    }

    let name: String
    let kind: Kind

    init(
        name: String,
        kind: Kind
    ) {
        self.name = name
        self.kind = kind
    }
}

extension PathTreeNode: Equatable {
    public static func == (lhs: PathTreeNode, rhs: PathTreeNode) -> Bool {
        return (lhs.name, lhs.kind) == (rhs.name, rhs.kind)
    }
}

extension PathTreeNode {
    static func file(name: String, isFolder: Bool = false) -> PathTreeNode {
        return PathTreeNode(name: name, kind: .file(isFolder: isFolder))
    }

    static func group(name: String, children: [PathTreeNode]) -> PathTreeNode {
        return PathTreeNode(name: name, kind: .group(children: children))
    }
}

extension PathTreeNode.Kind {
    static func group(children: [PathTreeNode]) -> PathTreeNode.Kind {
        return .group(.init(children: children))
    }
}

private class PathTreeNodeToVisit {
    let components: [String.SubSequence]
    let isFolder: Bool
    let children: [PathTreeNode]

    init(
        components: [String.SubSequence],
        isFolder: Bool = false,
        children: [PathTreeNode]
    ) {
        self.components = components
        self.isFolder = isFolder
        self.children = children
    }
}
