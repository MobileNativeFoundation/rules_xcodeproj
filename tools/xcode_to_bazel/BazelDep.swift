struct BazelDep: Equatable, Hashable {
    let module: String
    let repoName: String
    let version: String
    let order: Int

    init(module: String, repoName: String = "", version: String, order: Int) {
        self.module = module
        self.repoName = repoName
        self.version = version
        self.order = order
    }
}

extension BazelDep {
    static let rulesApple = Self(
        module: "rules_apple",
        repoName: "build_bazel_rules_apple",
        version: "3.1.1",
        order: 2
    )

    static let rulesSPM = Self(
        module: "rules_swift_package_manager",
        version: "0.25.0",
        order: 3
    )

    static let rulesSwift = Self(
        module: "rules_swift",
        repoName: "build_bazel_rules_swift",
        version: "1.15.0",
        order: 1
    )

    static let rulesXcodeproj = Self(
        module: "rules_xcodeproj",
        version: "1.15.0",
        order: 4
    )
}
