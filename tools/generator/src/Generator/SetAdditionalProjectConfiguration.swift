import PathKit
import XcodeProj

extension Generator {
    static func setAdditionalProjectConfiguration (
        _ pbxProj: PBXProj,
        _ resolvedExternalRepositories: [(Path, Path)]
    ) {
        let resolvedExternalRepositoriesString = resolvedExternalRepositories
            // Sorted by length to ensure that subdirectories are listed first
            .sorted { $0.0.string.count > $1.0.string.count }
            .map { #""\#($0)" "\#($1)""# }
            .joined(separator: " ")

        for configuration in pbxProj.buildConfigurations {
            configuration.buildSettings["RESOLVED_EXTERNAL_REPOSITORIES"] =
            resolvedExternalRepositoriesString
        }
    }
}
