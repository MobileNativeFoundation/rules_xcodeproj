import PBXProj

extension ElementCreator {
    /// This function exists, instead of simply reusing
    /// `handle{Non,}FileListPathNode`, to be as efficient as possible when we
    /// don't need to actually create `Element`s and just need to know what the
    /// `BazelPath`s would be. This happens when an element in the tree is a
    /// "folder type file" like localized files or CoreData models.
    static func collectBazelPaths(
        node: PathTreeNode,
        bazelPath: BazelPath
    ) -> [BazelPath] {
        if node.children.isEmpty {
            return [bazelPath]
        } else {
            var bazelPaths = node.children.flatMap { node in
                collectBazelPaths(
                    node: node,
                    bazelPath: bazelPath + node
                )
            }
            bazelPaths.append(bazelPath)
            return bazelPaths
        }
    }
}
