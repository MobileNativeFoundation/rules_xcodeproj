import PBXProj

extension Generator {
    struct CalculateTargetIdentifierMap {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates a map from target id to identifier.
        func callAsFunction(
            identifiedTargets: [IdentifiedTarget]
        ) -> [TargetID: Identifiers.Targets.Identifier] {
            return callable(
                /*identifiedTargets:*/ identifiedTargets
            )
        }
    }
}

// MARK: - CalculateTargetIdentifierMap.Callable

extension Generator.CalculateTargetIdentifierMap {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget]
    ) -> [TargetID: Identifiers.Targets.Identifier]

    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget]
    ) -> [TargetID: Identifiers.Targets.Identifier] {
        return Dictionary(
            uniqueKeysWithValues: identifiedTargets.flatMap { target in
                target.key.sortedIds.map { ($0, target.identifier) }
            }
        )
    }
}
