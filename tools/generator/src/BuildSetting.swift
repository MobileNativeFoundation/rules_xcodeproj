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
        case .string(let string):
            return string
        case .bool(let bool):
            return bool ? "YES" : "NO"
        case .array(let array):
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
    var asDictionary: [Key: Any] { self.mapValues { $0.asAny } }
}

// MARK: Decodable

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
