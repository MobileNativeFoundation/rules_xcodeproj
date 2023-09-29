import OrderedCollections
import PBXProj

extension Generator {
    struct CalculateIdentifiedTargetsMap {
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
        ) -> OrderedDictionary<TargetID, IdentifiedTarget> {
            return callable(
                /*identifiedTargets:*/ identifiedTargets
            )
        }
    }
}

// MARK: - CalculateIdentifiedTargetsMap.Callable

extension Generator.CalculateIdentifiedTargetsMap {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget]
    ) -> OrderedDictionary<TargetID, IdentifiedTarget>

    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget]
    ) -> OrderedDictionary<TargetID, IdentifiedTarget> {
        return OrderedDictionary(
            uniqueKeysWithValues: identifiedTargets.flatMap { target in
                target.key.sortedIds.map { ($0, target) }
            }
        )
    }
}
