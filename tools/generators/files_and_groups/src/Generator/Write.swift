import Foundation
import GeneratorCommon

extension Generator {
    /// Writes `content` to the file designated by `outputPath`.
    static func write(_ content: String, to outputPath: URL) throws {
        return try content.writeCreatingParentDirectories(to: outputPath)
    }
}
