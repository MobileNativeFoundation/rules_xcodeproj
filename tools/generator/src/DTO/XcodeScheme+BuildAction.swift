extension XcodeScheme {
    struct BuildAction: Equatable, Decodable {
        let targets: Set<TargetID>
    }
}
