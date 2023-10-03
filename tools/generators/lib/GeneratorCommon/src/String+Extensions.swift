import Foundation

extension String {
    /// Writes `self` to the file designated by `url`, creating parent
    /// directories if needed.
    public func writeCreatingParentDirectories(to url: URL) throws {
        do {
            // Create parent directory
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw PreconditionError(message: """
Failed to create parent directories for "\(url.path)": \
\(error.localizedDescription)
""")
        }

        // Write
        do {
            try write(to: url, atomically: false, encoding: .utf8)
        } catch {
            throw PreconditionError(message: """
Failed to write "\(url.path)": \(error.localizedDescription)
""")
        }
    }
}
