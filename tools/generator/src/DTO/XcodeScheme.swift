struct XcodeScheme: Equatable, Decodable {
    let name: String
    let buildAction: XcodeScheme.BuildAction?
    let testAction: XcodeScheme.TestAction?
    let launchAction: XcodeScheme.LaunchAction?
    let profileAction: XcodeScheme.ProfileAction?

    init(
        name: String,
        buildAction: XcodeScheme.BuildAction? = nil,
        testAction: XcodeScheme.TestAction? = nil,
        launchAction: XcodeScheme.LaunchAction? = nil,
        profileAction: XcodeScheme.ProfileAction? = nil
    ) {
        self.name = name
        self.buildAction = buildAction
        self.testAction = testAction
        self.launchAction = launchAction
        self.profileAction = profileAction
    }
}

extension XcodeScheme {
    struct BuildTarget: Equatable, Hashable, Decodable {
        let label: BazelLabel
        let buildFor: XcodeScheme.BuildFor

        init(
            label: BazelLabel,
            buildFor: XcodeScheme.BuildFor = .allEnabled
        ) {
            self.label = label
            self.buildFor = buildFor
        }
    }
}

extension XcodeScheme {
    struct BuildAction: Equatable, Decodable {
        let targets: Set<XcodeScheme.BuildTarget>

        init<BuildTargets: Sequence>(
            targets: BuildTargets
        ) where BuildTargets.Element == XcodeScheme.BuildTarget {
            // TODO(chuck): Add check to ensure that a label is only specified once
            self.targets = Set(targets)
        }
    }
}

// MARK: TestAction

extension XcodeScheme {
    struct TestAction: Equatable, Decodable {
        let buildConfigurationName: String
        let targets: Set<BazelLabel>

        init(
            targets: Set<BazelLabel>,
            buildConfigurationName: String = .defaultBuildConfigurationName
        ) {
            self.targets = targets
            self.buildConfigurationName = buildConfigurationName
        }
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

        init(
            target: BazelLabel,
            buildConfigurationName: String = .defaultBuildConfigurationName,
            args: [String] = [],
            env: [String: String] = [:],
            workingDirectory: String? = nil
        ) {
            self.target = target
            self.buildConfigurationName = buildConfigurationName
            self.args = args
            self.env = env
            self.workingDirectory = workingDirectory
        }
    }
}

// MARK: ProfileAction

extension XcodeScheme {
    struct ProfileAction: Equatable, Decodable {
        let buildConfigurationName: String
        let target: BazelLabel

        init(
            target: BazelLabel,
            buildConfigurationName: String = .defaultBuildConfigurationName
        ) {
            self.target = target
            self.buildConfigurationName = buildConfigurationName
        }
    }
}
