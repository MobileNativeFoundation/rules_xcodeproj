import PBXProj

extension Generator {
    /// Calculates the `RESOLVED_REPOSITORIES` build setting.
    static func resolvedRepositoriesBuildSetting(
        resolvedRepositories: [ResolvedRepository]
    ) -> String {
        return resolvedRepositories
            // Sorted by length to ensure that subdirectories are listed first
            .sorted { $0.mappedPath.count > $1.mappedPath.count }
            .map { #""\#($0.sourcePath)" "\#($0.mappedPath)""# }
            .joined(separator: " ")
    }
}
