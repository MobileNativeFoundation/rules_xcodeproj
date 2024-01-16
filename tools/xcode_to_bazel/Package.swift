import PathKit

struct LoadStatement {
    let bzlPath: String
    let symbols: [String]
}

struct Package {
    let path: Path
    var loadStatements: [String: Set<String>] = [:]
    var swiftPkgs: Set<String> = []
    var localSwiftPkgs: Set<String> = []
    var targets: [Target] = []
}

extension Package {
    mutating func addTarget(
        _ target: Target,
        requiredSymbols: [LoadableSymbol],
        swiftPkgs: [String] = [],
        localSwiftPkgs: [String] = []
    ) {
        targets.append(target)
        
        for loadableSymbol in requiredSymbols {
            loadStatements[loadableSymbol.bzlPath, default: []]
                .insert(loadableSymbol.symbol)
        }

        self.swiftPkgs.formUnion(swiftPkgs)
        self.localSwiftPkgs.formUnion(localSwiftPkgs)
    }
}
