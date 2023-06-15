import Foundation
import GeneratorCommon
import PBXProj

extension ElementCreator {
    #Injectable(asStatic: true) {
        /// Reads the file at `url`, returning the absolute path to the Bazel
        /// execution root.
        func readExecutionRootFile(_ url: URL) throws -> String {
            return try url.readExecutionRootFile()
        }
    }
}
