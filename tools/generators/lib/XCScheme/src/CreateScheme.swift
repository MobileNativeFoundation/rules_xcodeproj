public struct CreateScheme {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Creates the XML for an `.xcscheme` file.
    public func callAsFunction(
        buildAction: String,
        testAction: String,
        launchAction: String,
        profileAction: String,
        analyzeAction: String,
        archiveAction: String,
        wasCreatedForAppExtension: Bool
    ) -> String {
        return callable(
            /*buildAction:*/ buildAction,
            /*testAction:*/ testAction,
            /*launchAction:*/ launchAction,
            /*profileAction:*/ profileAction,
            /*analyzeAction:*/ analyzeAction,
            /*archiveAction:*/ archiveAction,
            /*wasCreatedForAppExtension:*/ wasCreatedForAppExtension
        )
    }
}

// MARK: - CreateScheme.Callable

extension CreateScheme {
    public typealias Callable = (
        _ buildAction: String,
        _ testAction: String,
        _ launchAction: String,
        _ profileAction: String,
        _ analyzeAction: String,
        _ archiveAction: String,
        _ wasCreatedForAppExtension: Bool
    ) -> String

    public static func defaultCallable(
        buildAction: String,
        testAction: String,
        launchAction: String,
        profileAction: String,
        analyzeAction: String,
        archiveAction: String,
        wasCreatedForAppExtension: Bool
    ) -> String {
        // 3 spaces for indentation is intentional
        return #"""
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "9999"
\#(
    wasCreatedForAppExtension ? #"""
   wasCreatedForAppExtension = "YES"

"""# : ""
)\#
   version = "\#(wasCreatedForAppExtension ? "2.0" : "1.7")">
\#(buildAction)
\#(testAction)
\#(launchAction)
\#(profileAction)
\#(analyzeAction)
\#(archiveAction)
</Scheme>

"""#
    }
}
