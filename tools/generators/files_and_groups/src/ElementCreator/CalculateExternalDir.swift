import GeneratorCommon

extension ElementCreator {
    struct CalculateExternalDir {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the absolute path to Bazel's External Repositories
        /// directory.
        ///
        /// - Parameters:
        ///   - executionRoot: The absolute path to Bazel's execution root.
        func callAsFunction(executionRoot: String) throws -> String {
            return try callable(/*executionRoot:*/ executionRoot)
        }
    }
}

// MARK: - CalculateExternalDir.Callable

extension ElementCreator.CalculateExternalDir {
    typealias Callable = (_ executionRoot: String) throws -> String

    static func defaultCallable(executionRoot: String) throws -> String {
        let components = executionRoot
            .split(separator: "/", omittingEmptySubsequences: false)

        guard components.count >= 4 else {
            // Need `executionRoot` to have `/path/execroot/main_repo` format
            throw PreconditionError(message: """
`executionRoot` does not have enough path components
""")
        }

        return "\(components.dropLast(2).joined(separator: "/"))/external"
    }
}
