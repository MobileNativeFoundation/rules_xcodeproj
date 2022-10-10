import XcodeProj

// MARK: Build with Bazel Specific Environment Variables

extension Array where Element == XCScheme.EnvironmentVariable {
    /// Provides the Bazel-specific environment variables for Build with Bazel
    /// launch action.
    ///
    /// For more information:
    /// https://docs.bazel.build/versions/main/user-manual.html#run
    static let bazelLaunchEnvironmentVariables: [XCScheme.EnvironmentVariable] = [
        .init(
            variable: "BUILD_WORKSPACE_DIRECTORY",
            value: "$(BUILD_WORKSPACE_DIRECTORY)",
            enabled: true
        ),
        .init(
            variable: "BUILD_WORKING_DIRECTORY",
            // By default, Xcode appears to set the working directory to the
            // BUILT_PRODUCTS_DIR.
            value: "$(BUILT_PRODUCTS_DIR)",
            enabled: true
        ),
    ].sortedLocalizedStandard()
}

// MARK: `sortedLocalizedStandard()`

extension Sequence where Element == XCScheme.EnvironmentVariable {
    func sortedLocalizedStandard() -> [XCScheme.EnvironmentVariable] {
        return sortedLocalizedStandard(\.variable)
    }
}

// MARK: `merged(with:)`

extension Sequence where Element == XCScheme.EnvironmentVariable {
    /// Merge the two sequences of environment variables together. Variables with the same name are
    /// merged using the following logic:
    /// - Variables from the `with` parameter replace those in `self`.
    /// - If variables from the `with` parameter have the same name, the last one wins.
    /// Results are sorted for consistent output.
    func merged<EnvVars: Sequence>(
        with others: EnvVars
    ) -> [XCScheme.EnvironmentVariable] where EnvVars.Element == XCScheme.EnvironmentVariable {
        var envVars = Dictionary(map { ($0.variable, $0) }) { lhs, _ in lhs }
        for other in others {
            envVars.updateValue(other, forKey: other.variable)
        }
        return envVars.values.sortedLocalizedStandard()
    }
}

// MARK: Helper to Create `XCScheme.EnvironmentVariable` Values

extension Dictionary where Key == String, Value == String {
    func asLaunchEnvironmentVariables() -> [XCScheme.EnvironmentVariable] {
        return map { .init(variable: $0, value: $1, enabled: true) }
    }
}
