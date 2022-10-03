import Foundation

// MARK: DiagnosticsInfo

extension XCSchemeInfo {
    struct DiagnosticsInfo: Equatable, Decodable {
        struct Sanitizers: Equatable, Decodable {
            let address: Bool
            let thread: Bool
            let undefinedBehavior: Bool
        }
        let sanitizers: Sanitizers?
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
        let sanitizers = diagnostics.sanitizers.map {
            XCSchemeInfo.DiagnosticsInfo.Sanitizers(
                address: $0.address,
                thread: $0.thread,
                undefinedBehavior: $0.undefinedBehavior
            )
        }
        self.init(
            sanitizers: sanitizers
        )
    }
}
