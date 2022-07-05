struct XcodeScheme: Equatable, Decodable {
    let name: String
    let buildAction: XcodeScheme.BuildAction?
    let testAction: XcodeScheme.TestAction?
    let launchAction: XcodeScheme.LaunchAction?
}
