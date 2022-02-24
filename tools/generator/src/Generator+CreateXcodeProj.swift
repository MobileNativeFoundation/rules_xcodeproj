import XcodeProj

extension Generator {
    /// Creates an `XcodeProj` for the given `PBXProj`.
    static func createXcodeProj(for pbxProj: PBXProj) -> XcodeProj {
        return XcodeProj(
            workspace: XCWorkspace(),
            pbxproj: pbxProj
        )
    }
}
