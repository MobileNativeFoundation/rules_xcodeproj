import PathKit
import XCTest

@testable import generator

extension Target {
    static func mock(
        configuration: String = "a1b2c",
        platform: Platform? = nil,
        product: Product,
        testHost: TargetID? = nil,
        buildSettings: [String: BuildSetting] = [:],
        inputs: Inputs = Inputs(),
        links: Set<Path> = [],
        dependencies: Set<TargetID> = []
    ) -> Self {
        return Target(
            name: product.name,
            label: "//\(product.name)",
            configuration: configuration,
            platform: platform ?? Platform(
                os: "macOS",
                arch: "arm64",
                minimumOsVersion: "12.0",
                environment: nil
            ),
            product: product,
            testHost: testHost,
            buildSettings: buildSettings,
            inputs: inputs,
            links: links,
            dependencies: dependencies
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
