extension XCSchemeInfo {
    struct BuildTarget: Equatable, Hashable {
        let targetInfo: XCSchemeInfo.TargetInfo
        let buildFor: BuildFor

        init(
            targetInfo: XCSchemeInfo.TargetInfo,
            buildFor: BuildFor = .init()
        ) {
            self.targetInfo = targetInfo
            self.buildFor = buildFor
        }
    }
}
