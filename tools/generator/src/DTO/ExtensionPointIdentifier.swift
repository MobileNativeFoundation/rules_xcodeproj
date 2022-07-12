enum ExtensionPointIdentifier: String, Decodable {
    case widgetKitExtension = "com.apple.widgetkit-extension"
    case unknown = ""

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = .init(rawValue: value) ?? .unknown
    }
}
