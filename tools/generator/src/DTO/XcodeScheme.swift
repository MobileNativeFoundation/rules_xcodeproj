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
    enum EnableBuildForValueMode {
        case merge
        case setIfAble
    }

    /// Create a new scheme applying any default actions based upon the current scheme.
    var withDefaults: XcodeScheme {
        get throws {
            var buildTargets = [BazelLabel: XcodeScheme.BuildTarget]()

            func enableBuildForValue(
                _ label: BazelLabel,
                _ keyPath: WritableKeyPath<XcodeScheme.BuildFor, XcodeScheme.BuildFor.Value>,
                _ mode: EnableBuildForValueMode = .merge
            ) throws {
                var buildTarget = buildTargets[label, default: .init(label: label, buildFor: .init())]
                switch mode {
                case .merge:
                    do {
                        try buildTarget.buildFor[keyPath: keyPath].merge(with: .enabled)
                    } catch XcodeScheme.BuildFor.Value.ValueError.incompatibleMerge {
                        throw UsageError(message: """
The `build_for` value, "\(keyPath.stringValue)", for "\(label)" in the "\(name)" Xcode scheme was \
disabled, but the target is referenced in the scheme's \(keyPath.actionType) action.
""")
                    }
                case .setIfAble:
                    buildTarget.buildFor[keyPath: keyPath].enableIfNotDisabled()
                }
                buildTargets[label] = buildTarget
            }

            // Populate the dictionary with any build targets that were
            // explicitly specified. We are guaranteed not to have build targets
            // with duplicate labels. So, we can just add these.
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
                    buildConfigurationName: launchAction.buildConfigurationName,
                    workingDirectory: launchAction.workingDirectory
                )
            } else {
                newProfileAction = nil
            }

            // Update the buildFor for the build targets
            try testAction?.targets.forEach { try enableBuildForValue($0, \.testing) }
            try launchAction.map { try enableBuildForValue($0.target, \.running) }
            try newProfileAction.map { try enableBuildForValue($0.target, \.profiling) }

            // If no build targets have running enabled, then enable it for all targets
            if !buildTargets.values.contains(where: \.buildFor.running.isEnabled) {
                try buildTargets.keys.forEach { try enableBuildForValue($0, \.running) }
            }

            // Enable archiving for any targets that have running enabled
            try buildTargets.values.filter(\.buildFor.running.isEnabled).map(\.label).forEach {
                try enableBuildForValue($0, \.archiving, .setIfAble)
            }

            // Enable analyze for all targets
            try buildTargets.keys.forEach { try enableBuildForValue($0, \.analyzing, .setIfAble) }

            // Create a new build action which includes all of the referenced labels as build targets
            // We must do this after processing all of the other actions.
            let newBuildAction = try XcodeScheme.BuildAction(
                targets: buildTargets.values,
                preActions: buildAction?.preActions ?? [],
                postActions: buildAction?.postActions ?? []
            )

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

// MARK: PrePostAction

extension XcodeScheme {
    struct PrePostAction: Equatable, Decodable {
        let name: String
        let expandVariablesBasedOn: BazelLabel?
        let script: String
    }
}

extension Sequence where Element == XcodeScheme.PrePostAction {
    func prePostActionInfos(
        buildConfigurationName: String,
        targetResolver: TargetResolver,
        targetIDsByLabelAndConfiguration: [String: [BazelLabel: TargetID]],
        context: String
    ) throws -> [XCSchemeInfo.PrePostActionInfo] {
        try map {
            try XCSchemeInfo.PrePostActionInfo(
                prePostAction: $0,
                buildConfigurationName: buildConfigurationName,
                targetResolver: targetResolver,
                targetIDsByLabelAndConfiguration:
                    targetIDsByLabelAndConfiguration,
                context: context
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
        let preActions: [PrePostAction]
        let postActions: [PrePostAction]

        init<BuildTargets: Sequence>(
            targets: BuildTargets,
            preActions: [PrePostAction] = [],
            postActions: [PrePostAction] = []
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
            self.preActions = preActions
            self.postActions = postActions
        }
    }
}

// MARK: TestAction

extension XcodeScheme {
    struct TestAction: Equatable {
        let buildConfigurationName: String?
        let targets: Set<BazelLabel>
        let args: [String]?
        let diagnostics: Diagnostics
        let env: [String: String]?
        let expandVariablesBasedOn: BazelLabel?
        let preActions: [PrePostAction]
        let postActions: [PrePostAction]

        init<Targets: Sequence>(
            targets: Targets,
            buildConfigurationName: String? = nil,
            args: [String]? = nil,
            diagnostics: Diagnostics = .init(),
            env: [String: String]? = nil,
            expandVariablesBasedOn: BazelLabel? = nil,
            preActions: [PrePostAction] = [],
            postActions: [PrePostAction] = []
        ) throws where Targets.Element == BazelLabel {
            self.targets = Set(targets)
            self.buildConfigurationName = buildConfigurationName
            self.args = args
            self.diagnostics = diagnostics
            self.env = env
            self.expandVariablesBasedOn = expandVariablesBasedOn
            self.preActions = preActions
            self.postActions = postActions

            guard !self.targets.isEmpty else {
                throw PreconditionError(message: """
No `BazelLabel` values were provided to `XcodeScheme.TestAction`.
""")
            }
        }
    }
}

extension XcodeScheme.TestAction: Decodable {
    enum CodingKeys: String, CodingKey {
        case buildConfigurationName = "buildConfiguration"
        case targets
        case args
        case diagnostics
        case env
        case expandVariablesBasedOn
        case preActions
        case postActions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        buildConfigurationName = try container
            .decodeIfPresent(String.self, forKey: .buildConfigurationName)
        targets = try container
            .decodeIfPresent(Set<BazelLabel>.self, forKey: .targets) ?? []
        args = try container
            .decodeIfPresent([String].self, forKey: .args)
        diagnostics = try container
            .decodeIfPresent(
                XcodeScheme.Diagnostics.self,
                forKey: .diagnostics
            ) ?? .init()
        env = try container
            .decodeIfPresent([String: String].self, forKey: .env)
        expandVariablesBasedOn = try container
            .decodeIfPresent(
                BazelLabel.self,
                forKey: .expandVariablesBasedOn
            )
        preActions = try container
            .decodeIfPresent(
                [XcodeScheme.PrePostAction].self,
                forKey: .preActions
            ) ?? []
        postActions = try container
            .decodeIfPresent(
                [XcodeScheme.PrePostAction].self,
                forKey: .postActions
            ) ?? []
    }
}

// MARK: Diagnostics

extension XcodeScheme {
    struct Diagnostics: Equatable {
        struct Sanitizers: Equatable {
            let address: Bool
            let thread: Bool
            let undefinedBehavior: Bool

            init(
                address: Bool = false,
                thread: Bool = false,
                undefinedBehavior: Bool = false
            ) {
                self.address = address
                self.thread = thread
                self.undefinedBehavior = undefinedBehavior
            }
        }

        let sanitizers: Sanitizers

        init(sanitizers: Sanitizers = .init()) {
            self.sanitizers = sanitizers
        }
    }
}

extension XcodeScheme.Diagnostics: Decodable {
    enum CodingKeys: String, CodingKey {
        case sanitizers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        sanitizers = try container
            .decodeIfPresent(Sanitizers.self, forKey: .sanitizers) ?? .init()
    }
}

extension XcodeScheme.Diagnostics.Sanitizers: Decodable {
    enum CodingKeys: String, CodingKey {
        case address
        case thread
        case undefinedBehavior
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        address = try container
            .decodeIfPresent(Bool.self, forKey: .address) ?? false
        thread = try container
            .decodeIfPresent(Bool.self, forKey: .thread) ?? false
        undefinedBehavior = try container
            .decodeIfPresent(Bool.self, forKey: .undefinedBehavior) ?? false
    }
}

// MARK: LaunchAction

extension XcodeScheme {
    struct LaunchAction: Equatable {
        let buildConfigurationName: String?
        let target: BazelLabel
        let args: [String]
        let diagnostics: Diagnostics
        let env: [String: String]
        let workingDirectory: String?

        init(
            target: BazelLabel,
            buildConfigurationName: String? = nil,
            args: [String] = [],
            diagnostics: Diagnostics = .init(),
            env: [String: String] = [:],
            workingDirectory: String? = nil
        ) {
            self.target = target
            self.buildConfigurationName = buildConfigurationName
            self.args = args
            self.diagnostics = diagnostics
            self.env = env
            self.workingDirectory = workingDirectory
        }
    }
}

extension XcodeScheme.LaunchAction: Decodable {
    enum CodingKeys: String, CodingKey {
        case buildConfigurationName = "buildConfiguration"
        case target
        case args
        case diagnostics
        case env
        case workingDirectory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        buildConfigurationName = try container
            .decodeIfPresent(String.self, forKey: .buildConfigurationName)
        target = try container.decode(BazelLabel.self, forKey: .target)
        args = try container
            .decodeIfPresent([String].self, forKey: .args) ?? []
        diagnostics = try container
            .decodeIfPresent(
                XcodeScheme.Diagnostics.self,
                forKey: .diagnostics
            ) ?? .init()
        env = try container
            .decodeIfPresent([String: String].self, forKey: .env) ?? [:]
        workingDirectory = try container
            .decodeIfPresent(String.self, forKey: .workingDirectory)
    }
}

// MARK: ProfileAction

extension XcodeScheme {
    struct ProfileAction: Equatable {
        let buildConfigurationName: String?
        let target: BazelLabel
        let args: [String]?
        let env: [String: String]?
        let workingDirectory: String?

        init(
            target: BazelLabel,
            buildConfigurationName: String? = nil,
            args: [String]? = nil,
            env: [String: String]? = nil,
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

extension XcodeScheme.ProfileAction: Decodable {
    enum CodingKeys: String, CodingKey {
        case buildConfigurationName = "buildConfiguration"
        case target
        case args
        case env
        case workingDirectory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        buildConfigurationName = try container
            .decodeIfPresent(String.self, forKey: .buildConfigurationName)
        target = try container.decode(BazelLabel.self, forKey: .target)
        args = try container
            .decodeIfPresent([String].self, forKey: .args)
        env = try container
            .decodeIfPresent([String: String].self, forKey: .env)
        workingDirectory = try container
            .decodeIfPresent(String.self, forKey: .workingDirectory)
    }
}
