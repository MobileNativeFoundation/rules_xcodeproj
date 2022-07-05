extension XcodeScheme {
    struct LaunchAction: Equatable, Decodable {
        let target: TargetID
        let args: [String]?
        let env: [String: String]?
        let workingDirectory: String?
    }
}
