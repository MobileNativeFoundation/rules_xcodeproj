import XcodeProj

extension Array where Element == XCScheme.EnvironmentVariable {
    /// Provides the Bazel-specific environment variables for Build with Bazel
    /// launch action.
    ///
    /// For more information:
    /// https://docs.bazel.build/versions/main/user-manual.html#run
    static let bazelLaunchVariables: [XCScheme.EnvironmentVariable] = [
        .init(
            variable: "BUILD_WORKSPACE_DIRECTORY",
            value: "$(SRCROOT)",
            enabled: true
        ),
        .init(
            variable: "BUILD_WORKING_DIRECTORY",
            // By default, Xcode appears to set the working directory to the
            // BUILT_PRODUCTS_DIR.
            value: "$(BUILT_PRODUCTS_DIR)",
            enabled: true
        ),
    ]
}
