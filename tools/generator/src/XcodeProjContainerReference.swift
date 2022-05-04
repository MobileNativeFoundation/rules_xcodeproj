import PathKit

/// In XcodeProj, a `referencedContainer` in a `XCScheme.BuildableReference`
/// accepts a string in the format `container:<path-to-xcodeproj-dir>`. This
/// type represents that structure.
public struct XcodeProjContainerReference: Equatable {
    public static let prefix = "container:"

    let workspaceOutputPath: Path
}

extension XcodeProjContainerReference: CustomStringConvertible {
    public var description: String {
        return "\(Self.prefix)\(workspaceOutputPath)"
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
            workspaceOutputPath: Path(String(value[range]))
        )
    }
}
