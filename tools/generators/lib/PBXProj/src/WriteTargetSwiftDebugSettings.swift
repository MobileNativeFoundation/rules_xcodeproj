import Foundation
import OrderedCollections

public struct WriteTargetSwiftDebugSettings {
    private let callable: Callable

    /// - Parameters:
    ///   - callable: The function that will be called in
    ///     `callAsFunction()`.
    public init(callable: @escaping Callable = Self.defaultCallable) {
        self.callable = callable
    }

    /// Writes the Swift debug settings for a certain target to disk.
    public func callAsFunction(
        clangArgs: [String],
        frameworkIncludes: OrderedSet<String>,
        swiftIncludes: OrderedSet<String>,
        to url: URL
    ) throws {
        try callable(
            /*clangArgs:*/ clangArgs,
            /*frameworkIncludes:*/ frameworkIncludes,
            /*swiftIncludes:*/ swiftIncludes,
            /*url:*/ url
        )
    }
}

// MARK: - WriteTargetSwiftDebugSettings.Callable

extension WriteTargetSwiftDebugSettings {
    public typealias Callable = (
        _ clangArgs: [String],
        _ frameworkIncludes: OrderedSet<String>,
        _ swiftIncludes: OrderedSet<String>,
        _ url: URL
    ) throws -> Void

    public static func defaultCallable(
        clangArgs: [String],
        frameworkIncludes: OrderedSet<String>,
        swiftIncludes: OrderedSet<String>,
        to url: URL
    ) throws {

        var data = Data()

        data.appendArgs(clangArgs)
        data.appendArgs(frameworkIncludes)
        data.appendArgs(swiftIncludes)

        try data.write(to: url)
    }
}

private extension Data {
    private static let separator = Data([0x0a]) // Newline

    mutating func appendArgs<Collection: RandomAccessCollection>(
        _ collection: Collection
    ) where Collection.Element == String {
        append(Data(String(collection.count).utf8))
        append(Self.separator)
        for arg in collection {
            append(Data(arg.newlinesToNulls.utf8))
            append(Self.separator)
        }
    }
}
