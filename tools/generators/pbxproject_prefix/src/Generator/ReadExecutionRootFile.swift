import Foundation
import GeneratorCommon

extension Generator {
    /// Reads the file at `url`, returning the absolute path to the Bazel
    /// execution root.
    static func readExecutionRootFile(_ url: URL) throws -> String {
        let lines: [String.SubSequence]
        do {
            lines = try String(contentsOf: url).split(separator: "\n")
        } catch {
            throw PreconditionError(message: error.localizedDescription)
        }

        guard lines.count == 1 else {
            throw PreconditionError(message: """
The execution_root_file must contain one line: the absolute path to the Bazel \
execution root.
""")
        }

        return String(lines[0])
    }
}
