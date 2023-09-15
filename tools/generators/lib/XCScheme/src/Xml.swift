import Foundation

extension Bool {
    var xmlString: String {
        return self ? "YES" : "NO"
    }
}

extension String {
    public var schemeXmlEscaped: String {
        return (CFXMLCreateStringByEscapingEntities(
            nil,
            self as CFString,
            nil
        )! as String).replacingOccurrences(of: "\n", with: "&#10;")
    }
}
