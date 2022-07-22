struct XcodeScheme: Equatable, Decodable {
    let name: String
    let buildAction: XcodeScheme.BuildAction?
    let testAction: XcodeScheme.TestAction?
    let launchAction: XcodeScheme.LaunchAction?

    init(
        name: String,
        buildAction: XcodeScheme.BuildAction? = nil,
        testAction: XcodeScheme.TestAction? = nil,
        launchAction: XcodeScheme.LaunchAction? = nil
    ) {
        self.name = name
        self.buildAction = buildAction
        self.testAction = testAction
        self.launchAction = launchAction
    }
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
        let buildConfigurationName: String
        let targets: Set<BazelLabel>
    }
}

// MARK: LaunchAction

extension XcodeScheme {
    struct LaunchAction: Equatable, Decodable {
        let buildConfigurationName: String
        let target: BazelLabel
        let args: [String]
        let env: [String: String]
        let workingDirectory: String?
    }
}
