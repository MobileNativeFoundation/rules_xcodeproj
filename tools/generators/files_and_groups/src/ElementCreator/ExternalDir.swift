import GeneratorCommon

extension ElementCreator {
    /// Calculates the absolute path to Bazel's External Repositories
    /// directory.
    ///
    /// - Parameters:
    ///   - executionRoot: The absolute path to Bazel's execution root.
    static func externalDir(executionRoot: String) throws -> String {
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
