import PathKit

/// In XcodeProj, a `referencedContainer` in a `XCScheme.BuildableReference`
/// accepts a string in the format `container:<path-to-xcodeproj-dir>`. This
/// type represents that structure.
public struct XcodeProjContainerReference: Equatable {
    public static let prefix = "container:"

    let xcodeprojPath: Path
}

extension XcodeProjContainerReference: CustomStringConvertible {
    public var description: String {
        return "\(Self.prefix)\(xcodeprojPath)"
    }
}

extension XcodeProjContainerReference: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        guard value.hasPrefix(Self.prefix) else {
            fatalError("Container references must begin with 'container:'.")
        }
        let startIndex = value.index(value.startIndex, offsetBy: Self.prefix.count)
        let range = startIndex...
        self = XcodeProjContainerReference(
            xcodeprojPath: Path(String(value[range]))
        )
    }
}
