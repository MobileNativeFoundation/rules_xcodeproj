import Foundation

// MARK: DiagnosticsInfo

extension XCSchemeInfo {
    struct DiagnosticsInfo: Equatable {
        struct Sanitizers: Equatable {
            let address: Bool
            let thread: Bool
            let undefinedBehavior: Bool
        }

        let sanitizers: Sanitizers
    }
}

// MARK: Custom Diagnostics Initializer

extension XCSchemeInfo.DiagnosticsInfo {
    init(
        diagnostics: XcodeScheme.Diagnostics
    ) {
        let sanitizers = XCSchemeInfo.DiagnosticsInfo.Sanitizers(
            address: diagnostics.sanitizers.address,
            thread: diagnostics.sanitizers.thread,
            undefinedBehavior: diagnostics.sanitizers.undefinedBehavior
        )
        self.init(
            sanitizers: sanitizers
        )
    }
}
