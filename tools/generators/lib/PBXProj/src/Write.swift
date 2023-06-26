import Foundation
import GeneratorCommon

public struct Write {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Writes `content` to the file designated by `outputPath`.
    public func callAsFunction(_ content: String, to outputPath: URL) throws {
        try callable(/*content:*/ content, /*to:*/ outputPath)
    }
}

// MARK: - Write.Callable

extension Write {
    public typealias Callable = (
        _ content: String,
        _ outputPath: URL
    ) throws -> Void

    /// Writes `content` to the file designated by `outputPath`.
    public static func defaultCallable(
        _ content: String,
        to outputPath: URL
    ) throws {
        return try content.writeCreatingParentDirectories(to: outputPath)
    }
}
