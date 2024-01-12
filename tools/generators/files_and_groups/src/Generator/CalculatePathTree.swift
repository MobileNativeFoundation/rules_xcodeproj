import AsyncAlgorithms
import Foundation
import PBXProj

extension Generator {
    /// - Precondition: No element of `paths` is a duplicate. If `paths` wasn't
    ///   an `AsyncSequence` it would be a `Set`.
    static func calculatePathTree(
        paths: AsyncChain2Sequence<AsyncMapSequence<AsyncLineSequence<URL.AsyncBytes>, BazelPath>, AsyncMapSequence<AsyncLineSequence<URL.AsyncBytes>, BazelPath>>
    ) async throws -> PathTreeNode {
        var nodesByComponentCount = try await withThrowingTaskGroup(
            of: [PathTreeNodeToVisit].self,
            returning: [Int: [PathTreeNodeToVisit]].self
        ) { group in
            // We chunk because the amount of work for each task is pretty
            // small, and we lose efficiency jumping between threads. We still
            // get some concurrency this way though (~35% faster).
            for try await chunk in paths.chunks(ofCount: 1024) {
                group.addTask {
                    return chunk.map { path in
                        return PathTreeNodeToVisit(
                            components:
                                ArraySlice(path.path.split(separator: "/")),
                            isFolder: path.isFolder,
                            children: []
                        )
                    }
                }
            }

            var nodesByComponentCount: [Int: [PathTreeNodeToVisit]] = [:]
            for try await nodesToVisit in group {
                for nodeToVisit in nodesToVisit {
                    nodesByComponentCount[
                        nodeToVisit.components.count,
                        default: []
                    ].append(nodeToVisit)
                }
            }

            return nodesByComponentCount
        }

        guard !nodesByComponentCount.isEmpty else {
            return PathTreeNode(name: "")
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

            let firstNode = sortedNodes[0]
            var collectingParentComponents = firstNode.components.dropLast(1)
            var collectingParentChildren: [PathTreeNode] = []
            var nodesForNextComponentCount: [PathTreeNodeToVisit] = []

            for node in sortedNodes {
                let parentComponents = node.components.dropLast(1)
                if parentComponents != collectingParentComponents {
                    nodesForNextComponentCount.append(
                        PathTreeNodeToVisit(
                            components: collectingParentComponents,
                            children: collectingParentChildren
                        )
                    )

                    collectingParentComponents = parentComponents
                    collectingParentChildren = []
                }

                collectingParentChildren.append(
                    PathTreeNode(
                        name: node.name,
                        nameNeedsPBXProjEscaping: node.nameNeedsPBXProjEscaping,
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
                    components: collectingParentComponents,
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
    let nameNeedsPBXProjEscaping: Bool
//    let pathNeedsPBXProjEscaping: Bool
    let isFolder: Bool
    let children: [PathTreeNode]

    init(
        name: String,
        nameNeedsPBXProjEscaping: Bool = false,
        isFolder: Bool = false,
        children: [PathTreeNode] = []
    ) {
        self.name = name
        self.nameNeedsPBXProjEscaping = nameNeedsPBXProjEscaping
//        self.pathNeedsPBXProjEscaping = nameNeedsPBXProjEscaping ||
//            children.contains { $0.pathNeedsPBXProjEscaping }
        self.isFolder = isFolder
        self.children = children
    }
}

private class PathTreeNodeToVisit {
    let name: String
    let nameNeedsPBXProjEscaping: Bool
    let components: ArraySlice<String.SubSequence>
    let isFolder: Bool
    let children: [PathTreeNode]

    init(
        components: ArraySlice<String.SubSequence>,
        isFolder: Bool = false,
        children: [PathTreeNode]
    ) {
        self.name = String(components.last!)
        self.nameNeedsPBXProjEscaping = name.needsPBXProjEscaping
        self.components = components
        self.isFolder = isFolder
        self.children = children
    }
}
