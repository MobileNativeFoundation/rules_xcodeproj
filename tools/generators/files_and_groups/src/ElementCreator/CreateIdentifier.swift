import PBXProj

extension ElementCreator {
    class CreateIdentifier {
        private let shard: UInt8
        private var hashCache: Set<String> = []

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            shard: UInt8,
            callable: @escaping Callable = Identifiers.FilesAndGroups.element
        ) {
            self.shard = shard
            self.callable = callable
        }

        /// See `Identifiers.FilesAndGroups.element` for details.
        func callAsFunction(
            path: String,
            name: String,
            type: Identifiers.FilesAndGroups.ElementType
        ) -> String {
            return callable(
                path,
                /*name:*/ name,
                /*type:*/ type,
                /*shard:*/ shard,
                /*hashCache:*/ &hashCache
            )
        }
    }
}

// MARK: - CreateIdentifier.Callable

extension ElementCreator.CreateIdentifier {
    typealias Callable = (
        _ path: String,
        _ name: String,
        _ type: Identifiers.FilesAndGroups.ElementType,
        _ shard: UInt8,
        _ hashCache: inout Set<String>
    ) -> String
}
