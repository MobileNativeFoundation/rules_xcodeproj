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
            // This is a poor substitute for the working directory.
            // Preferably, it would be $(PWD) or something similar.
            // Unfortunately, none of the following worked:
            //   $(PWD), $PWD, ${PWD}, \$(pwd), $\(pwd\)
            value: "$(SRCROOT)",
            enabled: true
        ),
    ]
}
