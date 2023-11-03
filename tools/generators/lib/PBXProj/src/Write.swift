import Foundation
import ToolCommon

public struct Write {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Writes `content` to the file designated by `outputPath`.
    public func callAsFunction(
        _ content: String,
        to outputPath: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try callable(
            /*content:*/ content,
            /*to:*/ outputPath,
            /*file:*/ file,
            /*line:*/ line
        )
    }
}

// MARK: - Write.Callable

extension Write {
    public typealias Callable = (
        _ content: String,
        _ outputPath: URL,
        _ file: StaticString,
        _ line: UInt
    ) throws -> Void

    /// Writes `content` to the file designated by `outputPath`.
    public static func defaultCallable(
        _ content: String,
        to outputPath: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        return try content.writeCreatingParentDirectories(
            to: outputPath,
            file: file,
            line: line
        )
    }
}
