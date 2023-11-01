import Foundation
import ToolCommon

/// A type that generates and writes to disk the `swift_debug_settings.py` file
/// for a given Xcode configuration.
///
/// The `Generator` type is stateless. It can be used to generate files for
/// multiple Xcode configurations. The `generate()` method is passed all the
/// inputs needed to generate the file.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `swift_debug_settings.py` file and writes it to disk.
    func generate(rawArguments: ArraySlice<String>) async throws {
        var rawArguments = rawArguments

        let outputPath =
            try rawArguments.consumeArg("output-path", as: URL.self)

        guard rawArguments.count.isMultiple(of: 2) else {
            throw PreconditionError(message: """
<keys-and-files> must be <key> and <file> pairs
""")
        }

        var keysAndFiles: [(key: String, url: URL)] = []
        for _ in (0..<(rawArguments.count/2)) {
            let key = try rawArguments.consumeArg("key")
            let url = try rawArguments.consumeArg("file", as: URL.self)
            keysAndFiles.append((key, url))
        }

        try environment.writeSwiftDebugSettings(
            await environment
                .readKeyedSwiftDebugSettings(keysAndFiles: keysAndFiles),
            to: outputPath
        )
    }
}

private extension ArraySlice<String> {
    mutating func consumeArg(
        _ name: String,
        as type: URL.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> URL {
        return try consumeArg(
            name,
            as: type,
            transform: { URL(fileURLWithPath: $0, isDirectory: false) },
            file: file,
            line: line
        )
    }
}
