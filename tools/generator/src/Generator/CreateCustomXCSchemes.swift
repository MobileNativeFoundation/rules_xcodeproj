import PathKit
import XcodeProj

extension Generator {
    /// Creates an array of `XCScheme` entries from the scheme descriptions.
    static func createCustomXCSchemes(
        schemes: [XcodeScheme],
        buildMode: BuildMode,
        targetResolver: TargetResolver,
        runnerLabel: BazelLabel
    ) throws -> [XCScheme] {
        return try schemes.map { scheme in
            let schemeInfo = try XCSchemeInfo(
                scheme: scheme,
                targetResolver: targetResolver,
                runnerLabel: runnerLabel
            )
            return try XCScheme(buildMode: buildMode, schemeInfo: schemeInfo)
        }
    }
}
