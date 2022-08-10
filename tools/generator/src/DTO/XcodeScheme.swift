
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
    ) throws {
        guard buildAction != nil || testAction != nil || launchAction != nil ||
            profileAction != nil
        else {
            throw PreconditionError(message: """
No actions were provided for the scheme "\(name)".
""")
        }
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
                do {
                    try buildTargets[label, default: .init(label: label, buildFor: .init())]
                        .buildFor[keyPath: keyPath]
                        .merge(with: .enabled)
                } catch XcodeScheme.BuildFor.Value.ValueError.incompatibleMerge {
                    throw UsageError(message: """
The `build_for` value, "\(keyPath.stringValue)", for "\(label)" in the "\(name)" Xcode scheme was \
disabled, but the target is referenced in the scheme's \(keyPath.actionType) action.
""")
                }
            }

            // Popuate the dictionary with any build targets that were explicitly specified.
            // We are guaranteed not to have build targets with duplicate labels. So, we can just
            // add these.
            buildAction?.targets.forEach { buildTargets[$0.label] = $0 }

            // Default ProfileAction
            let newProfileAction: XcodeScheme.ProfileAction?
            if let profileAction = profileAction {
                newProfileAction = profileAction
            } else if let launchAction = launchAction,
                buildTargets[launchAction.target]?.buildFor.profiling != .disabled
            {
                newProfileAction = .init(
                    target: launchAction.target,
                    buildConfigurationName: launchAction.buildConfigurationName
                )
            } else {
                newProfileAction = nil
            }

            // Update the buildFor for the build targets
            try testAction?.targets.forEach { try enableBuildForValue($0, \.testing) }
            try launchAction.map { try enableBuildForValue($0.target, \.running) }
            try newProfileAction.map { try enableBuildForValue($0.target, \.profiling) }

            // If no build targets have running enabled, then enable it for all targets
            if !buildTargets.values.contains(where: { $0.buildFor.running == .enabled }) {
                try buildTargets.keys.forEach { try enableBuildForValue($0, \.running) }
            }

            // Create a new build action which includes all of the referenced labels as build targets
            // We must do this after processing all of the other actions.
            let newBuildAction = try XcodeScheme.BuildAction(targets: buildTargets.values)

            return try .init(
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
            let targetsByLabel = Dictionary(grouping: targets, by: \.label)
            guard !targetsByLabel.isEmpty else {
                throw PreconditionError(message: """
No `XcodeScheme.BuildTarget` values were provided to `XcodeScheme.BuildAction`.
""")
            }
            for (label, targets) in targetsByLabel {
                guard targets.count == 1 else {
                    throw PreconditionError(message: """
Found a duplicate label \(label) in provided `XcodeScheme.BuildTarget` values.
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

        init<Targets: Sequence>(
            targets: Targets,
            buildConfigurationName: String = .defaultBuildConfigurationName
        ) throws where Targets.Element == BazelLabel {
            self.targets = Set(targets)
            self.buildConfigurationName = buildConfigurationName

            guard !self.targets.isEmpty else {
                throw PreconditionError(message: """
No `BazelLabel` values were provided to `XcodeScheme.TestAction`.
""")
            }
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
