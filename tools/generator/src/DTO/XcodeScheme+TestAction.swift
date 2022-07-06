extension XcodeScheme {
    struct TestAction: Equatable, Decodable {
        let targets: Set<String>
    }
}
