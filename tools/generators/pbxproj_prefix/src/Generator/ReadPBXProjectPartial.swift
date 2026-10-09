import Foundation
import ToolCommon

extension Generator {
    /// Reads the `PBXProject` property `PBXProj` partial at `url`.
    static func readPBXProjectPartial(_ url: URL) throws -> String {
        do {
            return try String(contentsOf: url)
        } catch {
            throw PreconditionError(message: error.localizedDescription)
        }
    }
}
