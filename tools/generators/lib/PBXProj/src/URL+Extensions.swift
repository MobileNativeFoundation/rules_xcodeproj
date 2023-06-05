import Foundation
import GeneratorCommon

extension URL {
    /// Reads the file at `self`, returning the absolute path to the Bazel
    /// execution root.
    public func readExecutionRootFile() throws -> String {
        let lines: [String.SubSequence]
        do {
            lines = try String(contentsOf: self).split(separator: "\n")
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
