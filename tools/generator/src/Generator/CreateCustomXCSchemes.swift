import PathKit
import XcodeProj

extension Generator {
    /// Creates an array of `XCScheme` entries from the scheme descriptions.
    static func createCustomXCSchemes(
        schemes _: [XcodeScheme],
        buildMode _: BuildMode,
        targetResolver _: TargetResolver
    ) throws -> [XCScheme] {
        // GH573: Implement custom scheme creation
        return []
    }
}
