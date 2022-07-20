import XcodeProj

extension XCSchemeInfo {
    struct HostInfo: Equatable {
        let pbxTarget: PBXTarget
        let buildableReference: XCScheme.BuildableReference
        let index: Int

        init(pbxTarget: PBXTarget, referencedContainer: String, index: Int) {
             self.pbxTarget = pbxTarget
             buildableReference = .init(
                 pbxTarget: pbxTarget,
                 referencedContainer: referencedContainer
             )
             self.index = index
        }
    }
}
