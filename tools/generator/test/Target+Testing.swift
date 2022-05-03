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
            platform: platform ?? Platform(
                os: .macOS,
                arch: "arm64",
                minimumOsVersion: "12.0",
                environment: nil
            ),
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
