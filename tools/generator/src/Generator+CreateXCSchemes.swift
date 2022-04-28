import XcodeProj

extension Generator {
    /// Creates an array of `XCScheme` entries for the specified targets.
    static func createXCSchemes(
        disambiguatedTargets _: [TargetID: DisambiguatedTarget]
    ) -> [XCScheme] {
        // GH101: Implement logic to create schemes from targets.
        return []
    }
}
