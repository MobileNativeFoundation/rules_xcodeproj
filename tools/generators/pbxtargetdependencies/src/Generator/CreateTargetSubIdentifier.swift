import PBXProj

extension Generator {
    class CreateTargetSubIdentifier {
        private var hashCache: [UInt8: Set<String>] = [:]

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable = Identifiers.Targets.subIdentifier
        ) {
            self.callable = callable
        }

        /// - See `Identifiers.Targets.subIdentifier()` for details.
        func callAsFunction(
            _ targetId: TargetID,
            shard: UInt8
        ) -> Identifiers.Targets.SubIdentifier {
            return callable(
                targetId,
                /*shard:*/ shard,
                /*hashCache:*/ &hashCache
            )
        }
    }
}

// MARK: - CreateTargetSubIdentifier.Callable

extension Generator.CreateTargetSubIdentifier {
    typealias Callable = (
        _ targetId: TargetID,
        _ shard: UInt8,
        _ hashCache: inout [UInt8: Set<String>]
    ) -> Identifiers.Targets.SubIdentifier
}
