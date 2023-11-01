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

        data.append(Data(String(clangArgs.count).utf8))
        data.append(separator)
        for arg in clangArgs {
            data.append(Data(arg.utf8))
            data.append(separator)
        }

        data.append(Data(String(frameworkIncludes.count).utf8))
        data.append(separator)
        for include in frameworkIncludes {
            data.append(Data(include.utf8))
            data.append(separator)
        }

        data.append(Data(String(swiftIncludes.count).utf8))
        data.append(separator)
        for include in swiftIncludes {
            data.append(Data(include.utf8))
            data.append(separator)
        }

        try data.write(to: url)
    }
}

private let separator = Data([0x0a]) // Newline
