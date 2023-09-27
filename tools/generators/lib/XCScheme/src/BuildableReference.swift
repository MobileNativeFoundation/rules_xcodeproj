public struct BuildableReference: Equatable, Hashable {
    public let blueprintIdentifier: String
    let buildableName: String
    public let blueprintName: String
    let referencedContainer: String

    public init(
        blueprintIdentifier: String,
        buildableName: String,
        blueprintName: String,
        referencedContainer: String
    ) {
        self.blueprintIdentifier = blueprintIdentifier
        self.buildableName = buildableName
        self.blueprintName = blueprintName
        self.referencedContainer = referencedContainer
    }
}
