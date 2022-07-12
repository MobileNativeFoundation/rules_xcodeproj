struct XcodeScheme: Equatable, Decodable {
    let name: String
    let buildAction: XcodeScheme.BuildAction?
    let testAction: XcodeScheme.TestAction?
    let launchAction: XcodeScheme.LaunchAction?
}

// MARK: LabelValue

extension XcodeScheme {
    // The Bazel label as a string (Target.label)
    typealias LabelValue = String
}

// MARK: BuildAction

extension XcodeScheme {
    struct BuildAction: Equatable, Decodable {
        let targets: Set<LabelValue>
    }
}

// MARK: TestAction

extension XcodeScheme {
    struct TestAction: Equatable, Decodable {
        let targets: Set<LabelValue>
    }
}

// MARK: LaunchAction

extension XcodeScheme {
    struct LaunchAction: Equatable, Decodable {
        let target: LabelValue
        let args: [String]
        let env: [String: String]
        let workingDirectory: String?
    }
}
