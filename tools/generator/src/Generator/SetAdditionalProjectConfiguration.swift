import PathKit
import XcodeProj

extension Generator {
    static func setAdditionalProjectConfiguration(
        _ pbxProj: PBXProj,
        _ resolvedRepositories: [(Path, Path)]
    ) {
        let resolvedRepositoriesString = resolvedRepositories
            // Sorted by length to ensure that subdirectories are listed first
            .sorted { $0.1.string.count > $1.1.string.count }
            .map { #""\#($0)" "\#($1)""# }
            .joined(separator: " ")

        for configuration in pbxProj.buildConfigurations {
            configuration.buildSettings["RESOLVED_REPOSITORIES"] =
                resolvedRepositoriesString
        }
    }
}
