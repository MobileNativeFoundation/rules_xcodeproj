import PathKit
import XcodeProj

extension Generator {
    /// Creates an array of `XCScheme` entries from the scheme descriptions.
    static func createCustomXCSchemes(
        schemes: [XcodeScheme],
        buildMode: BuildMode,
        xcodeConfigurations: Set<String>,
        defaultBuildConfigurationName: String,
        targetResolver: TargetResolver,
        runnerLabel: BazelLabel,
        args: [TargetID: [String]],
        envs: [TargetID: [String: String]]
    ) throws -> [XCScheme] {
        return try schemes.map { scheme in
            let schemeInfo = try XCSchemeInfo(
                scheme: scheme,
                xcodeConfigurations: xcodeConfigurations,
                defaultBuildConfigurationName: defaultBuildConfigurationName,
                targetResolver: targetResolver,
                runnerLabel: runnerLabel,
                args: args,
                envs: envs
            )
            return try XCScheme(buildMode: buildMode, schemeInfo: schemeInfo)
        }
    }
}
