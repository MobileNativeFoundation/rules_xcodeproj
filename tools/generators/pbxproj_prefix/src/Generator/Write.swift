import GeneratorCommon
import Foundation

extension Generator {
    /// Writes `projPrefix` to the file designated by `outputPath`.
    static func write(_ projPrefix: String, to outputPath: URL) throws {
        return try projPrefix.writeCreatingParentDirectories(to: outputPath)
    }
}
