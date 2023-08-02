import PBXProj

extension Generator {
    struct CalculateTargetDependenciesPartial {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `PBXTargetDependencies` and `PBXContainerItemProxy`
        /// partial.
        func callAsFunction(objects: [Object]) -> String {
            return callable(/*objects:*/ objects)
        }
    }
}

// MARK: - CalculateTargetDependenciesPartial.Callable

extension Generator.CalculateTargetDependenciesPartial {
    typealias Callable = (_ objects: [Object]) -> String

    static func defaultCallable(objects: [Object]) -> String {
        return
            objects.map { "\t\t\($0.identifier) = \($0.content);\n" }.joined()
    }
}
