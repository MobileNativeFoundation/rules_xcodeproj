import OrderedCollections
import PathKit
import XCTest

@testable import generator

extension Target {
    static func mock(
        label: String? = nil,
        configuration: String = "a1b2c",
        packageBinDir: Path = "bazel-out/a1b2c/some/package",
        platform: Platform? = nil,
        product: Product,
        isSwift: Bool = false,
        testHost: TargetID? = nil,
        buildSettings: [String: BuildSetting] = [:],
        searchPaths: SearchPaths = .init(),
        modulemaps: [FilePath] = [],
        swiftmodules: [FilePath] = [],
        resourceBundleDependencies: Set<TargetID> = [],
        inputs: Inputs = .init(),
        linkerInputs: LinkerInputs = .init(),
        dependencies: Set<TargetID> = [],
        outputs : Outputs = .init()
    ) -> Self {
        return Target(
            name: product.name,
            label: label ?? "//some/package:\(product.name)",
            configuration: configuration,
            packageBinDir: packageBinDir,
            platform: platform ?? .macOS(),
            product: product,
            isSwift: isSwift,
            testHost: testHost,
            buildSettings: buildSettings,
            searchPaths: searchPaths,
            modulemaps: modulemaps,
            swiftmodules: swiftmodules,
            inputs: inputs,
            linkerInputs: linkerInputs,
            resourceBundleDependencies: resourceBundleDependencies,
            dependencies: dependencies,
            outputs: outputs
        )
    }
}

extension Platform {
    static func simulator(
        os: Platform.OS = .iOS,
        arch: String = "arm64",
        minimumOsVersion: String = "11.0"
    ) -> Self {
        let name: String
        switch os {
        case .macOS: preconditionFailure("use `.macOS`")
        case .iOS: name = "iphonesimulator"
        case .tvOS: name = "appletvsimulator"
        case .watchOS: name = "watchsimulator"
        }

        return Platform(
            name: name,
            os: os,
            arch: arch,
            minimumOsVersion: minimumOsVersion,
            environment: "Simulator"
        )
    }

    static func device(
        os: Platform.OS = .iOS,
        arch: String = "arm64",
        minimumOsVersion: String = "11.0"
    ) -> Self {
        let name: String
        switch os {
        case .macOS: preconditionFailure("use `.macOS`")
        case .iOS: name = "iphoneos"
        case .tvOS: name = "appletvos"
        case .watchOS: name = "watchos"
        }

        return Platform(
            name: name,
            os: os,
            arch: arch,
            minimumOsVersion: minimumOsVersion,
            environment: nil
        )
    }

    static func macOS(
        arch: String = "arm64",
        minimumOsVersion: String = "11.0"
    ) -> Self {
        return Platform(
            name: "macosx",
            os: .macOS,
            arch: arch,
            minimumOsVersion: minimumOsVersion,
            environment: nil
        )
    }
}

extension ConsolidatedTargets {
    init(targets: [TargetID: Target]) {
        var keys: [TargetID: ConsolidatedTarget.Key] = [:]
        var consolidatedTargets: [ConsolidatedTarget.Key: ConsolidatedTarget] =
            [:]

        for (id, target) in targets {
            let key = ConsolidatedTarget.Key([id])
            keys[id] = key
            consolidatedTargets[key] = ConsolidatedTarget(targets: [id: target])
        }

        self.init(keys: keys, targets: consolidatedTargets)
    }

    init(allTargets: [TargetID: Target], keys: Set<Set<TargetID>>) {
        var mapping: [TargetID: ConsolidatedTarget.Key] = [:]
        var consolidatedTargets: [ConsolidatedTarget.Key: ConsolidatedTarget] =
            [:]

        for targetIDs in keys {
            let key = ConsolidatedTarget.Key(targetIDs)
            for targetID in targetIDs {
                mapping[targetID] = key
            }
            consolidatedTargets[key] = ConsolidatedTarget(
                targets: allTargets.filter { id, _ in targetIDs.contains(id) }
            )
        }

        self.init(keys: mapping, targets: consolidatedTargets)
    }
}

extension ConsolidatedTarget.Key: Comparable {
    public static func < (
        lhs: ConsolidatedTarget.Key,
        rhs: ConsolidatedTarget.Key
    ) -> Bool {
        return lhs.hashValue < rhs.hashValue
    }
}

// MARK: StringLiteralConvertible

extension ConsolidatedTarget.Key: ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    public init(extendedGraphemeClusterLiteral id: StringLiteralType) {
        self.init(stringLiteral: id)
    }

    public init(unicodeScalarLiteral id: StringLiteralType) {
        self.init(stringLiteral: id)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init([TargetID(stringLiteral: value)])
    }
}

extension TargetID: ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    public init(extendedGraphemeClusterLiteral id: StringLiteralType) {
        self.init(stringLiteral: id)
    }

    public init(unicodeScalarLiteral id: StringLiteralType) {
        self.init(stringLiteral: id)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

extension FilePath: ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    public init(extendedGraphemeClusterLiteral path: StringLiteralType) {
        self = .project(Path(path))
    }

    public init(unicodeScalarLiteral path: StringLiteralType) {
        self = .project(Path(path))
    }

    public init(stringLiteral value: StringLiteralType) {
        self = .project(Path(value))
    }
}
