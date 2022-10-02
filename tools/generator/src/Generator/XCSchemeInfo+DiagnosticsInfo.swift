import Foundation

// MARK: DiagnosticsInfo

extension XCSchemeInfo {
    struct DiagnosticsInfo: Equatable, Decodable {
        let enableAddressSanitizer: Bool
        let enableThreadSanitizer: Bool
        let enableUndefinedBehaviorSanitizer: Bool
    }
}

// MARK: Custom Diagnostics Initializer

extension XCSchemeInfo.DiagnosticsInfo {
    init?(
        diagnostics: XcodeScheme.Diagnostics?
    ) {
        guard let diagnostics = diagnostics else {
            return nil
        }
        self.init(
            enableAddressSanitizer: diagnostics.enableAddressSanitizer,
            enableThreadSanitizer: diagnostics.enableThreadSanitizer,
            enableUndefinedBehaviorSanitizer: diagnostics.enableUndefinedBehaviorSanitizer
        )
    }
}
