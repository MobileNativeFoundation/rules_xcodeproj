import GeneratorCommon

extension Generator {
    struct CalculateCreatedOnToolsVersion {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates
        /// `PBXProject.attributes.TargetAttributes.CreatedOnToolsVersion`.
        func callAsFunction(
            minimumXcodeVersion: SemanticVersion
        ) -> String {
            return callable(
                /*minimumXcodeVersion:*/ minimumXcodeVersion
            )
        }
    }
}

// MARK: - CalculateCreatedOnToolsVersion.Callable

extension Generator.CalculateCreatedOnToolsVersion {
    typealias Callable = (
        _ minimumXcodeVersion: SemanticVersion
    ) -> String

    static func defaultCallable(
        minimumXcodeVersion: SemanticVersion
    ) -> String {
        return minimumXcodeVersion.full
    }
}
