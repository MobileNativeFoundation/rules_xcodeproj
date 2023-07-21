public struct CreateBuildSettingsAttribute {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Calculates the `buildSettings` attribute of a `XCBuildConfiguration`
    /// element.
    public func callAsFunction(buildSettings: [BuildSetting]) -> String {
        return callable(/*buildSettings:*/ buildSettings)
    }
}

// MARK: - CreateBuildSettingsAttribute.Callable

extension CreateBuildSettingsAttribute {
    public typealias Callable = (_ buildSettings: [BuildSetting]) -> String

    public static func defaultCallable(buildSettings: [BuildSetting]) -> String {
        // The tabs for indenting are intentional
        return #"""
{
\#(
    buildSettings
        .sorted()
        .map { "\t\t\t\t\($0.key) = \($0.value);\n" }
        .joined()
)\#
			}
"""#
    }
}
