enum ExtensionPointIdentifier: String, Decodable {
    case messagePayloadProvider = "com.apple.message-payload-provider"
    case widgetKitExtension = "com.apple.widgetkit-extension"
    case unknown = ""

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = .init(rawValue: value) ?? .unknown
    }
}

extension ExtensionPointIdentifier {
    var debuggingMode: Int {
        switch self {
        case .messagePayloadProvider:
            return 1
        default:
            return 2
        }
    }

    var remoteBundleIdentifier: String {
        switch self {
        case .messagePayloadProvider:
            return "com.apple.MobileSMS"
        default:
            return "com.apple.springboard"
        }
    }
}
