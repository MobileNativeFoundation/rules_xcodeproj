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

        /// This function exists to be as efficient as possible when we don't
        /// need to actually create `Element`s and just need to know what the
        /// `BazelPath`s would be. This happens when an element in the tree is a
        /// "folder type file" like localized files or CoreData models.
        func callAsFunction(
            node: PathTreeNode,
            bazelPath: BazelPath,
            includeSelf: Bool
        ) -> [BazelPath] {
            return callable(
                /*node:*/ node,
                /*bazelPath:*/ bazelPath,
                /*includeSelf:*/ includeSelf
            )
        }
    }
}

// MARK: - CollectBazelPaths.Callable

extension ElementCreator.CollectBazelPaths {
    typealias Callable = (
        _ node: PathTreeNode,
        _ bazelPath: BazelPath,
        _ includeSelf: Bool
    ) -> [BazelPath]

    static func defaultCallable(
        node: PathTreeNode,
        bazelPath: BazelPath,
        includeSelf: Bool
    ) -> [BazelPath] {
        switch node {
        case .file:
            return includeSelf ? [bazelPath] : []
        case .group(_, let children):
            var bazelPaths = children.flatMap { node in
                return handleChildNode(node, parentBazelPath: bazelPath)
            }
            if includeSelf {
                bazelPaths.append(bazelPath)
            }
            return bazelPaths
        case .generatedFiles:
            // Impossible to have generated files under localized or model files
            fatalError()
        }
    }

    static func handleChildNode(
        _ node: PathTreeNode,
        parentBazelPath: BazelPath
    ) -> [BazelPath] {
        switch node {
        case .file(let name):
            let bazelPath = BazelPath(
                parent: parentBazelPath,
                path: name
            )
            return [bazelPath]
        case .group(let name, let children):
            let bazelPath = BazelPath(
                parent: parentBazelPath,
                path: name
            )
            var bazelPaths = children.flatMap { node in
                return handleChildNode(node, parentBazelPath: bazelPath)
            }
            bazelPaths.append(bazelPath)
            return bazelPaths
        case .generatedFiles:
            // Impossible to have generated files under localized or model files
            fatalError()
        }
    }
}
