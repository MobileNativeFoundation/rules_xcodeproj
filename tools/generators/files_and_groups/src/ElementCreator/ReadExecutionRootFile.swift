import Foundation
import PBXProj

extension ElementCreator {
    /// Reads the file at `url`, returning the absolute path to the Bazel
    /// execution root.
    static func readExecutionRootFile(_ url: URL) throws -> String {
        return try url.readExecutionRootFile()
    }
}
