import ToolCommon

extension Generator {
    /// Calculates the `PBXProject.compatibilityVersion` string.
    ///
    /// - Parameters:
    ///   - minimumXcodeVersion: The minimum Xcode version that the generated
    ///     project supports.
    ///   - buildableFolders: Whether Xcode 16 buildable folders are enabled.
    static func compatibilityVersion(
        minimumXcodeVersion: SemanticVersion,
        buildableFolders: Bool
    ) -> String {
        let majorVersion = projectObjectMajorVersion(
            minimumXcodeVersion: minimumXcodeVersion,
            buildableFolders: buildableFolders
        )
        return "Xcode \(majorVersion).0"
    }
}

func projectObjectMajorVersion(
    minimumXcodeVersion: SemanticVersion,
    buildableFolders: Bool
) -> Int {
    if minimumXcodeVersion.major >= 16 && buildableFolders {
        return 16
    }

    return min(minimumXcodeVersion.major, 15)
}
