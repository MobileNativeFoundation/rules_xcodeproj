import Foundation

public struct ReadTargetSwiftDebugSettingsFile {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Reads the Swift debug settings for a specific target from a file.
    public  func callAsFunction(
        from url: URL
    ) async throws -> TargetSwiftDebugSettings {
        try await callable(/*url:*/ url)
    }
}

// MARK: - ReadTargetSwiftDebugSettingsFile.Callable

extension ReadTargetSwiftDebugSettingsFile {
    public typealias Callable =
        (_ url: URL) async throws -> TargetSwiftDebugSettings

    public static func defaultCallable(
        url: URL
    ) async throws -> TargetSwiftDebugSettings {
        return try await .decode(from: url)
    }
}
