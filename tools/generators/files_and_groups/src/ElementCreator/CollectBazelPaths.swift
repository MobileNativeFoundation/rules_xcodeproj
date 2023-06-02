import PBXProj

extension ElementCreator {
    struct CollectBazelPaths {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// This function exists, instead of simply reusing
        /// `handle{Non,}FileListPathNode`, to be as efficient as possible when
        /// we don't need to actually create `Element`s and just need to know
        /// what the `BazelPath`s would be. This happens when an element in the
        /// tree is a "folder type file" like localized files or CoreData
        /// models.
        func callAsFunction(
            node: PathTreeNode,
            bazelPath: BazelPath
        ) -> [BazelPath] {
            return callable(
                /*node:*/ node,
                /*bazelPath:*/ bazelPath
            )
        }
    }
}

// MARK: - CollectBazelPaths.Callable

extension ElementCreator.CollectBazelPaths {
    typealias Callable = (
        _ node: PathTreeNode,
        _ bazelPath: BazelPath
    ) -> [BazelPath]

    static func defaultCallable(
        node: PathTreeNode,
        bazelPath: BazelPath
    ) -> [BazelPath] {
        if node.children.isEmpty {
            return [bazelPath]
        } else {
            var bazelPaths = node.children.flatMap { node in
                defaultCallable(
                    node: node,
                    bazelPath: bazelPath + node
                )
            }
            bazelPaths.append(bazelPath)
            return bazelPaths
        }
    }
}
