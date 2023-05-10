import Foundation

extension Generator {
    /// Writes `bazelDependencies` to the file designated by `outputPath`.
    static func write(
        _ bazelDependencies: String,
        to outputPath: URL
    ) throws {
        // Create parent directory
        try FileManager.default.createDirectory(
            at: outputPath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Write
        try bazelDependencies
            .write(to: outputPath, atomically: false, encoding: .utf8)
    }
}
