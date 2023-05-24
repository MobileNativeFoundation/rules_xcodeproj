import Foundation

extension String {
    /// Writes `self` to the file designated by `outputPath`, creating parent
    /// directories if needed.
    public func writeCreatingParentDirectories(to outputPath: URL) throws {
        // Create parent directory
        try FileManager.default.createDirectory(
            at: outputPath.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Write
        try write(to: outputPath, atomically: false, encoding: .utf8)
    }
}
