import OrderedCollections
import PathKit
import XcodeProj
import XCTest

@testable import generator

extension Target {
    static func mock(
        label: BazelLabel? = nil,
        configuration: String = "a1b2c",
        compileTarget: CompileTarget? = nil,
        packageBinDir: Path = "bazel-out/a1b2c/some/package",
        platform: Platform? = nil,
        product: Product,
        isTestonly: Bool = false,
        isSwift: Bool = false,
        testHost: TargetID? = nil,
        buildSettings: [String: BuildSetting] = [:],
        searchPaths: SearchPaths = .init(),
        modulemaps: [FilePath] = [],
        swiftmodules: [FilePath] = [],
        inputs: Inputs = .init(),
        linkerInputs: LinkerInputs = .init(),
        resourceBundleDependencies: Set<TargetID> = [],
        watchApplication: TargetID? = nil,
        extensions: Set<TargetID> = [],
        appClips: Set<TargetID> = [],
        dependencies: Set<TargetID> = [],
        outputs: Outputs = .init(),
        lldbContext: LLDBContext? = nil,
        isUnfocusedDependency: Bool = false
    ) -> Self {
        return Target(
            name: product.name,
            label: label ?? .init(nilIfInvalid: "//some/package:\(product.name)")!,
            configuration: configuration,
            compileTarget: compileTarget,
            packageBinDir: packageBinDir,
            platform: platform ?? .macOS(),
            product: product,
            isTestonly: isTestonly,
            isSwift: isSwift,
            testHost: testHost,
            buildSettings: buildSettings,
            searchPaths: searchPaths,
            modulemaps: modulemaps,
            swiftmodules: swiftmodules,
            inputs: inputs,
            linkerInputs: linkerInputs,
            resourceBundleDependencies: resourceBundleDependencies,
            watchApplication: watchApplication,
            extensions: extensions,
            appClips: appClips,
            dependencies: dependencies,
            outputs: outputs,
            lldbContext: lldbContext,
            isUnfocusedDependency: isUnfocusedDependency
        )
    }
}

extension Platform {
    static func simulator(
        os: Platform.OS = .iOS,
        arch: String = "arm64",
        minimumOsVersion: SemanticVersion = "11.0"
    ) -> Self {
        var variant: Variant {
            switch os {
            case .macOS: preconditionFailure("use `.macOS`")
            case .iOS: return .iOSSimulator
            case .tvOS: return .tvOSSimulator
            case .watchOS: return .watchOSSimulator
            }
        }

        return Platform(
            os: os,
            variant: variant,
            arch: arch,
            minimumOsVersion: minimumOsVersion
        )
    }

    static func device(
        os: Platform.OS = .iOS,
        arch: String = "arm64",
        minimumOsVersion: SemanticVersion = "11.0"
    ) -> Self {
        var variant: Variant {
            switch os {
            case .macOS: preconditionFailure("use `.macOS`")
            case .iOS: return .iOSDevice
            case .tvOS: return .tvOSDevice
            case .watchOS: return .watchOSDevice
            }
        }

        return Platform(
            os: os,
            variant: variant,
            arch: arch,
            minimumOsVersion: minimumOsVersion
        )
    }

    static func macOS(
        arch: String = "arm64",
        minimumOsVersion: SemanticVersion = "11.0"
    ) -> Self {
        return Platform(
            os: .macOS,
            variant: .macOS,
            arch: arch,
            minimumOsVersion: minimumOsVersion
        )
    }
}

extension ConsolidatedTarget {
    init(targets: [TargetID: Target]) {
        self.init(targets: targets, xcodeGeneratedFiles: [:])
    }
}

extension ConsolidatedTargets {
    init(
        targets: [TargetID: Target],
        xcodeGeneratedFiles: [FilePath: FilePath] = [:]
    ) {
        var keys: [TargetID: ConsolidatedTarget.Key] = [:]
        var consolidatedTargets: [ConsolidatedTarget.Key: ConsolidatedTarget] =
            [:]

        for (id, target) in targets {
            let key = ConsolidatedTarget.Key([id])
            keys[id] = key
            consolidatedTargets[key] = ConsolidatedTarget(
                targets: [id: target],
                xcodeGeneratedFiles: xcodeGeneratedFiles
            )
        }

        self.init(keys: keys, targets: consolidatedTargets)
    }

    init(
        allTargets: [TargetID: Target],
        keys: Set<Set<TargetID>>,
        xcodeGeneratedFiles: [FilePath: FilePath] = [:]
    ) {
        var mapping: [TargetID: ConsolidatedTarget.Key] = [:]
        var consolidatedTargets: [ConsolidatedTarget.Key: ConsolidatedTarget] =
            [:]

        for targetIDs in keys {
            let key = ConsolidatedTarget.Key(targetIDs)
            for targetID in targetIDs {
                mapping[targetID] = key
            }
            consolidatedTargets[key] = ConsolidatedTarget(
                targets: allTargets.filter { id, _ in targetIDs.contains(id) },
                xcodeGeneratedFiles: xcodeGeneratedFiles
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

extension SemanticVersion: ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    public init(extendedGraphemeClusterLiteral id: StringLiteralType) {
        self.init(stringLiteral: id)
    }

    public init(unicodeScalarLiteral id: StringLiteralType) {
        self.init(stringLiteral: id)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(version: value)!
    }
}
