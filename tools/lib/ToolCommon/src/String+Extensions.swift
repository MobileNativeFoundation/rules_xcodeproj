import Foundation

extension String {
    /// Writes `self` to the file designated by `url`, creating parent
    /// directories if needed.
    public func writeCreatingParentDirectories(
        to url: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        do {
            // Create parent directory
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            throw PreconditionError(
                message: url.prefixMessage("""
Failed to create parent directories: \(error.localizedDescription)
"""),
                file: file,
                line: line
            )
        }

        // Write
        do {
            try write(to: url, atomically: false, encoding: .utf8)
        } catch {
            throw PreconditionError(
                message: url.prefixMessage("""
Failed to write: \(error.localizedDescription)
"""),
                file: file,
                line: line
            )
        }
    }
}
