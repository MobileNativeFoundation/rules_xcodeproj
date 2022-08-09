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
    /// Create a new scheme applying any default actions based upon the current scheme.
    var withDefaults: XcodeScheme {
        get throws {
            var buildTargets = [BazelLabel: XcodeScheme.BuildTarget]()

            func enableBuildForValue(
                _ label: BazelLabel,
                _ keyPath: WritableKeyPath<XcodeScheme.BuildFor, XcodeScheme.BuildFor.Value>
            ) throws {
                // var buildTarget = buildTargets[
                //     label,
                //     default: .init(label: label, buildFor: .init())
                // ]
                // try buildTarget.buildFor[keyPath: keyPath].merge(with: .enabled)
                // buildTargets[label] = buildTargetInfo
                try buildTargets[label, default: .init(label: label, buildFor: .init())]
                    .buildFor[keyPath: keyPath]
                    .merge(with: .enabled)
            }

            // Popuate the dictionary with any build targets that were explicitly specified.
            // We are guaranteed not to have build targets with duplicate labels. So, we can just
            // add these.
            buildAction?.targets.forEach { buildTargets[$0.label] = $0 }

            // Default ProfileAction
            let newProfileAction: XcodeScheme.ProfileAction?
            if let launchAction = launchAction,
                profileAction == nil,
                buildTargets[launchAction.target]?.buildFor.profiling != .disabled
            {
                newProfileAction = .init(
                    target: launchAction.target,
                    buildConfigurationName: launchAction.buildConfigurationName
                )
            } else if let profileAction = profileAction {
                newProfileAction = profileAction
            } else {
                newProfileAction = nil
            }

            // Update the buildFor for the build targets
            try testAction?.targets.forEach { try enableBuildForValue($0, \.testing) }
            try launchAction.map { try enableBuildForValue($0.target, \.running) }
            try newProfileAction.map { try enableBuildForValue($0.target, \.profiling) }

            // Create a new build action which includes all of the referenced labels as build targets
            // We must do this after processing all of the other actions.
            let newBuildAction = try XcodeScheme.BuildAction(targets: buildTargets.values)

            return .init(
                name: name,
                buildAction: newBuildAction,
                testAction: testAction,
                launchAction: launchAction,
                profileAction: newProfileAction
            )
        }
    }
}

// MARK: BuildAction

extension XcodeScheme {
    struct BuildTarget: Equatable, Hashable, Decodable {
        let label: BazelLabel
        var buildFor: XcodeScheme.BuildFor

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
        ) throws where BuildTargets.Element == XcodeScheme.BuildTarget {
            var labels = Set<BazelLabel>()
            for target in targets {
                let (inserted, _) = labels.insert(target.label)
                guard inserted else {
                    throw PreconditionError(message: """
Found a duplicate label \(target.label) in provided `XcodeScheme.BuildTarget` values.
""")
                }
            }

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
