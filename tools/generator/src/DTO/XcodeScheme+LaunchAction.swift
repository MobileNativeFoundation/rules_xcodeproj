extension XcodeScheme {
    struct LaunchAction: Equatable, Decodable {
        let target: String
        let args: [String]
        let env: [String: String]
        let workingDirectory: String?
    }
}
