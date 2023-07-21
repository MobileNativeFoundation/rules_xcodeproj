import PBXProj

typealias BuildSettings = [(key: String, value: String)]

extension Generator {
    struct CalculateBuildSettingsAttribute {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `buildSettings` attribute of a target's
        /// `XCBuildConfiguration` element.
        func callAsFunction(buildSettings: BuildSettings) -> String {
            return callable(/*buildSettings:*/ buildSettings)
        }
    }
}

// MARK: - CalculateBuildSettingsAttribute.Callable

extension Generator.CalculateBuildSettingsAttribute {
    typealias Callable = (_ buildSettings: BuildSettings) -> String

    static func defaultCallable(buildSettings: BuildSettings) -> String {
        // The tabs for indenting are intentional
        return #"""
{
\#(
    buildSettings
        .sorted { $0.key < $1.key }
        .map { (key, value) in
            return "\t\t\t\t\(key) = \(value);"
        }
        .joined(separator: "\n")
)
			}
"""#
    }
}
