import XCScheme

extension Array where Element == EnvironmentVariable {
    static let defaultEnvironmentVariables: [EnvironmentVariable] = [
        .init(
            key: "BUILD_WORKING_DIRECTORY",
            value: "$(BUILT_PRODUCTS_DIR)"
        ),
        .init(
            key: "BUILD_WORKSPACE_DIRECTORY",
            value: "$(BUILD_WORKSPACE_DIRECTORY)"
        ),
    ]
}
