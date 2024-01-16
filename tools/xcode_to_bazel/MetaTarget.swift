struct MetaTarget {
    let target: Target
    let requiredSymbols: [LoadableSymbol]
    let intentDefinitions: [String]
    let canBeTransitiveDep: Bool

    init(
        target: Target,
        intentDefinitions: [String] = [],
        requiredSymbols: [LoadableSymbol] = [],
        canBeTransitiveDep: Bool = true
    ) {
        self.target = target
        self.intentDefinitions = intentDefinitions
        self.requiredSymbols = requiredSymbols + [target.kind.loadableSymbol]
        self.canBeTransitiveDep = canBeTransitiveDep
    }
}
