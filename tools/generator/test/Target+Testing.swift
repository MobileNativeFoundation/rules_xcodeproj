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
        resourceBundles: Set<FilePath> = [],
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
            resourceBundles: resourceBundles,
            inputs: inputs,
            linkerInputs: linkerInputs,
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

// MARK: StringLiteralConvertible

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
