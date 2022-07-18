import XcodeProj

extension XCScheme {
    struct SchemeInfo {
        let name: String
        let buildInfo: XCScheme.SchemeInfo.BuildInfo?
        let testInfo: XCScheme.SchemeInfo.TestInfo?
        let launchInfo: XCScheme.SchemeInfo.LaunchInfo?
    }
}
