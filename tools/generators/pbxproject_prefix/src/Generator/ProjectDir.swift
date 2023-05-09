import PBXProj

extension Generator {
    /// Calculates the `PBXProject.projectDir` string.
    ///
    /// - Parameters:
    ///   - executionRoot: The absolute path to the Bazel execution root.
    static func projectDir(executionRoot: String) -> String {
        guard !executionRoot.hasPrefix("/private/") else {
            // We remove the "/private" prefix so the path is the same as you
            // get when using `.standardizingPath()`, which Xcode uses. If we
            // don't do this, we run into issues in Xcode.
            return String(executionRoot.dropFirst(8))
        }
        return executionRoot
    }
}
