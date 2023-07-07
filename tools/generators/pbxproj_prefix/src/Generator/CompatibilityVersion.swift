import GeneratorCommon

extension Generator {
    /// Calculates the `PBXProject.compatibilityVersion` string.
    ///
    /// - Parameters:
    ///   - minimumXcodeVersion: The minimum Xcode version that the generated
    ///     project supports.
    static func compatibilityVersion(
        minimumXcodeVersion: SemanticVersion
    ) -> String {
        return "Xcode \(min(minimumXcodeVersion.major, 15)).0"
    }
}
