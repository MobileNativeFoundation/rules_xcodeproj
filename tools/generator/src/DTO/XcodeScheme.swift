struct XcodeScheme: Equatable, Decodable {
    let name: String
    let buildAction: XcodeScheme.BuildAction?
    let testAction: XcodeScheme.TestAction?
    let launchAction: XcodeScheme.LaunchAction?
}

// MARK: BuildAction

extension XcodeScheme {
    struct BuildAction: Equatable, Decodable {
        let targets: Set<BazelLabel>
    }
}

// MARK: TestAction

extension XcodeScheme {
    struct TestAction: Equatable, Decodable {
        let targets: Set<BazelLabel>
    }
}

// MARK: LaunchAction

extension XcodeScheme {
    struct LaunchAction: Equatable, Decodable {
        let target: BazelLabel
        let args: [String]
        let env: [String: String]
        let workingDirectory: String?
    }
}
