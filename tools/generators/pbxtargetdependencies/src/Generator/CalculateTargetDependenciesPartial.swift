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
        func callAsFunction(elements: [Element]) -> String {
            return callable(/*elements:*/ elements)
        }
    }
}

// MARK: - CalculateTargetDependenciesPartial.Callable

extension Generator.CalculateTargetDependenciesPartial {
    typealias Callable = (_ elements: [Element]) -> String

    static func defaultCallable(elements: [Element]) -> String {
        return elements
            .map { "\t\t\($0.identifier) = \($0.content);\n" }
            .joined()
    }
}
