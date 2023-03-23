/// A custom type to aid in decoding build setting dictionaries.
///
/// `[String: Any]` isn't `Decodable`, so we use `[String: BuildSetting]` to
/// represent build settings in our data transfer objects. The expected use case
/// is for a `[String: BuildSetting]` to be created with a `JSONDecoder` and for
/// `asDictionary` to be called on it at the place of use.
enum BuildSetting: Equatable {
    case string(String)
    case bool(Bool)
    case array([String])
}

extension BuildSetting {
    /// Converts the build setting to its native representation (e.g. `.array`
    /// becomes an array of `String`s).
    var asAny: Any {
        switch self {
        case let .string(string):
            return string
        case let .bool(bool):
            return bool ? "YES" : "NO"
        case let .array(array):
            guard array.count > 1 else {
                // Xcode formats arrays of 0 or 1 strings as a string
                return array.first ?? ""
            }
            return array
        }
    }
}

extension Dictionary where Value == BuildSetting {
    /// Converts the build settings to `[String: Any]`.
    var asDictionary: [Key: Any] { mapValues { $0.asAny } }
}

// MARK: - Decodable

extension BuildSetting: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }
        if let array = try? container.decode([String].self) {
            self = .array(array)
            return
        }
        throw DecodingError.typeMismatch(
            BuildSetting.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected to decode String/[String]"
            )
        )
    }
}

// MARK: - ExpressibleByStringLiteral

extension BuildSetting: ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }

    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }

    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

// MARK: - ExpressibleByBooleanLiteral

extension BuildSetting: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension BuildSetting: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: String...) {
        self = .array(elements)
    }
}

// MARK: - Convenience

extension Dictionary where Value == BuildSetting {
    mutating func set(_ key: Key, to value: Bool) {
        self[key] = .bool(value)
    }

    mutating func set(_ key: Key, to value: String) {
        self[key] = .string(value)
    }

    mutating func set(_ key: Key, to value: [String]) {
        self[key] = .array(value)
    }
}
