import ToolCommon

extension Generator {
    struct CalculateSchemeReferencedContainer {
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
            installPath: String,
            workspace: String
        ) -> String {
            return callable(
                /*installPath:*/ installPath,
                /*workspace:*/ workspace
            )
        }
    }
}

// MARK: - CalculateSchemeReferencedContainer.Callable

extension Generator.CalculateSchemeReferencedContainer {
    typealias Callable = (
        _ installPath: String,
        _ workspace: String
    ) -> String

    static func defaultCallable(
        installPath: String,
        workspace: String
    ) -> String {
        return "container:\(workspace)/\(installPath)"
    }
}
