import XcodeProj

extension Array where Element == XCScheme.EnvironmentVariable {
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

    /// For more information:
    /// https://bazel.build/reference/test-encyclopedia#initial-conditions
    static func createBazelTestVariables(workspaceName: String) -> [XCScheme.EnvironmentVariable] {
        // TODO(chuck): Add other TEST_XXX variables
        return [
            .init(
                variable: "TEST_SRCDIR",
                // TODO(chuck): Confirm this value
                value: "$(SRCROOT)",
                enabled: true
            ),
            .init(
                variable: "TEST_WORKSPACE",
                value: workspaceName,
                enabled: true
            ),
        ]
    }
}
