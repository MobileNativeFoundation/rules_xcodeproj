import Foundation
import GeneratorCommon

extension Generator {
    /// Reads the file at `url`, returning the pre/post-build script.
    static func readPrePostBuildScript(_ url: URL?) throws -> String? {
        do {
            return try url.flatMap(String.init(contentsOf:))
        } catch {
            throw PreconditionError(message: error.localizedDescription)
        }
    }
}
