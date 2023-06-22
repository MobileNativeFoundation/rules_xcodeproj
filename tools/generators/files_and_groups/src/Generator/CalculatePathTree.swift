import PBXProj

extension Generator {
    static func calculatePathTree(paths: Set<BazelPath>) -> PathTreeNode {
        guard !paths.isEmpty else {
            return PathTreeNode(name: "")
        }

        var nodesByComponentCount: [Int: [PathTreeNodeToVisit]] = [:]
        for path in paths {
            let components = path.path.split(separator: "/")
            nodesByComponentCount[components.count, default: []]
                .append(PathTreeNodeToVisit(
                    components: components,
                    isFolder: path.isFolder,
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
                       // We properly sort in `CreateGroupChildElements`, so w
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

            let firstNode = sortedNodes[0]
            var collectingParentComponents = firstNode.components.dropLast(1)
            var collectingParentChildren: [PathTreeNode] = []
            var nodesForNextComponentCount: [PathTreeNodeToVisit] = []

            for node in sortedNodes {
                let parentComponents = node.components.dropLast(1)
                if parentComponents != collectingParentComponents {
                    nodesForNextComponentCount.append(
                        PathTreeNodeToVisit(
                            components: Array(collectingParentComponents),
                            children: collectingParentChildren
                        )
                    )

                    collectingParentComponents = parentComponents
                    collectingParentChildren = []
                }

                collectingParentChildren.append(
                    PathTreeNode(
                        name: String(node.components.last!),
                        isFolder: node.isFolder,
                        children: node.children
                    )
                )
            }

            guard componentCount != 1 else {
                // Root node
                return PathTreeNode(
                    name: "",
                    children: collectingParentChildren
                )
            }

            // Last node
            nodesForNextComponentCount.append(
                PathTreeNodeToVisit(
                    components: Array(collectingParentComponents),
                    children: collectingParentChildren
                )
            )

            nodesByComponentCount[componentCount - 1, default: []]
                .append(contentsOf: nodesForNextComponentCount)
        }

        // This is unreachable because of the guard in the the `for` loop above.
        // We iterate down to `1`, and the guard catches on `1`.
        fatalError()
    }
}

class PathTreeNode {
    let name: String
    let isFolder: Bool
    let children: [PathTreeNode]

    init(
        name: String,
        isFolder: Bool = false,
        children: [PathTreeNode] = []
    ) {
        self.name = name
        self.isFolder = isFolder
        self.children = children
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
