import PathKit
import XCTest

@testable import generator

extension Target {
    static func mock(
        configuration: String = "a1b2c",
        product: Product,
        buildSettings: [String: BuildSetting] = [:],
        srcs: Set<Path> = [],
        links: Set<Path> = [],
        dependencies: Set<TargetID> = []
    ) -> Self {
        return Target(
            name: product.name,
            label: "//\(product.name)",
            configuration: configuration,
            product: product,
            buildSettings: buildSettings,
            srcs: srcs,
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
