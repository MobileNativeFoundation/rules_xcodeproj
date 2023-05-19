import PBXProj

extension Generator {
    /// Calculates the `INDEXING_PROJECT_DIR__YES` build setting.
    ///
    /// - Parameters:
    ///   - projectDir: The value returned from `Generator.projectDir()`.
    static func indexingProjectDir(projectDir: String) -> String {
        let projectDirComponents = projectDir
            .split(separator: "/", omittingEmptySubsequences: false)

        // /some/path/build_output_base/execroot/_main -> /some/path/indexbuild_output_base/execroot/_main
        return (
            projectDirComponents.prefix(upTo: projectDirComponents.count - 3) +
            ["indexbuild_output_base"] +
            projectDirComponents.suffix(2)
        ).joined(separator: "/")
    }
}
