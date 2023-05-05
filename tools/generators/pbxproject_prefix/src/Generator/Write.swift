import Foundation

extension Generator {
    /// Writes the `projectPrefix` to the file designated by `outputPath`.
    static func write(
        _ projectPrefix: String,
        to outputPath: URL
    ) throws {
        // Create parent directory
        try FileManager.default.createDirectory(
            at: outputPath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Write
        try projectPrefix
            .write(to: outputPath, atomically: false, encoding: .utf8)
    }
}
