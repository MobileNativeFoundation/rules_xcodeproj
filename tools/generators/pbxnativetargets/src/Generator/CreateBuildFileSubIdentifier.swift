import PBXProj

extension Generator {
    class CreateBuildFileSubIdentifier {
        private var hashCache: [UInt8: Set<String>] = [:]

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable = Identifiers.BuildFiles.subIdentifier
        ) {
            self.callable = callable
        }

        /// - See `Identifiers.Targets.subIdentifier()` for details.
        func callAsFunction(
            _ path: BazelPath,
            type: Identifiers.BuildFiles.FileType,
            shard: UInt8
        ) -> Identifiers.BuildFiles.SubIdentifier {
            return callable(
                path,
                /*type:*/ type,
                /*shard:*/ shard,
                /*hashCache:*/ &hashCache
            )
        }
    }
}

// MARK: - CreateBuildFileSubIdentifier.Callable

extension Generator.CreateBuildFileSubIdentifier {
    typealias Callable = (
        _ path: BazelPath,
        _ type: Identifiers.BuildFiles.FileType,
        _ shard: UInt8,
        _ hashCache: inout [UInt8: Set<String>]
    ) -> Identifiers.BuildFiles.SubIdentifier
}
