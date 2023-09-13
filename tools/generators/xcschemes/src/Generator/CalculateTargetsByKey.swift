import PBXProj

extension Generator {
    struct CalculateTargetsByKey {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `referencedContainer` attribute on `.xcscheme`
        /// `BuildableReference` elements.
        func callAsFunction(
            targets: [Target]
        ) -> (
            targetsByKey: [Target.Key: Target],
            targetsByID: [TargetID: Target]
        ) {
            return callable(
                /*targets:*/ targets
            )
        }
    }
}

// MARK: - CalculateTargetsByKey.Callable

extension Generator.CalculateTargetsByKey {
    typealias Callable = (
        _ targets: [Target]
    ) -> (
        targetsByKey: [Target.Key: Target],
        targetsByID: [TargetID: Target]
    )

    static func defaultCallable(
        targets: [Target]
    ) -> (
        targetsByKey: [Target.Key: Target],
        targetsByID: [TargetID: Target]
    ) {
        return (
            targetsByKey: Dictionary(
                uniqueKeysWithValues: targets.map { target in
                    return (target.key, target)
                }
            ),
            targetsByID: Dictionary(
                uniqueKeysWithValues: targets.flatMap { target in
                    return target.key.sortedIds.map { ($0, target) }
                }
            )
        )
    }
}
