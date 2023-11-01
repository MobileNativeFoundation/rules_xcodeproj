import Foundation

extension Generator {
    struct WriteBuildSettings {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Writes the build settings to disk.
        func callAsFunction(
            _ buildSettings: [(key: String, value: String)],
            to url: URL
        ) throws {
            try callable(/*buildSettings:*/ buildSettings, /*url:*/ url)
        }
    }
}

// MARK: - WriteBuildSettings.Callable

extension Generator.WriteBuildSettings {
    typealias Callable = (
        _ buildSettings: [(key: String, value: String)],
        _ url: URL
    ) throws -> Void

    static func defaultCallable(
        _ buildSettings: [(key: String, value: String)],
        to url: URL
    ) throws {
        var data = Data()

        for (key, value) in buildSettings
            .sorted(by: { $0.key < $1.key })
        {
            data.append(Data(key.utf8))
            data.append(subSeparator)
            data.append(Data(value.utf8))
            data.append(separator)
        }

        try data.write(to: url)
    }
}

private let separator = Data([0x0a]) // Newline
private let subSeparator = Data([0x09]) // Tab
