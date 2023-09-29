public struct BuildSetting {
    /// The `.pbxProjEscaped` key.
    let key: String

    /// The `.pbxProjEscaped` value.
    let value: String

    /// If non-`nil`, this will be used for `Comparable` instead of
    /// `pbxProjEscapedKey`. This must be set when `pbxProjEscapedKey` is an
    /// escaped value, otherwise the build setting will be sorted incorrectly
    /// (because of the `"` at the start of the key).
    fileprivate let explicitSortKey: String?
}

extension BuildSetting {
    public init(key: String, value: String) {
        self.init(key: key, value: value, explicitSortKey: nil)
    }

    public init(key: String, pbxProjEscapedKey: String, value: String) {
        self.init(key: pbxProjEscapedKey, value: value, explicitSortKey: key)
    }
}

extension BuildSetting: Comparable {
    private var sortKey: String { explicitSortKey ?? key }

    public static func < (lhs: BuildSetting, rhs: BuildSetting) -> Bool {
        return lhs.sortKey < rhs.sortKey
    }
}

// For tests
extension Array where Element == BuildSetting {
    public var asDictionary: [String: String] {
        return Dictionary(uniqueKeysWithValues: map { ($0.key, $0.value) })
    }
}
