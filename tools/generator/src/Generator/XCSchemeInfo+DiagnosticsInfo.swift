import Foundation

// MARK: DiagnosticsInfo

extension XCSchemeInfo {
    struct DiagnosticsInfo: Equatable, Decodable {
        struct Sanitizers: Equatable, Decodable {
            let address: Bool
            let thread: Bool
            let undefinedBehavior: Bool
        }
        let sanitizers: Sanitizers
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
        let sanitizers = XCSchemeInfo.DiagnosticsInfo.Sanitizers(
            address: diagnostics.sanitizers?.address ?? false,
            thread: diagnostics.sanitizers?.thread ?? false,
            undefinedBehavior: diagnostics.sanitizers?.undefinedBehavior ?? false
        )
        self.init(
            sanitizers: sanitizers
        )
    }
}
