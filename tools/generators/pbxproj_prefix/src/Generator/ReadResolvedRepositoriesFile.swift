import Foundation
import GeneratorCommon

extension Generator {
    /// Reads the file at `url`, returning the string for the
    /// `RESOLVED_REPOSITORIES` build setting.
    static func readResolvedRepositoriesFile(_ url: URL) throws -> String {
        let lines: [String.SubSequence]
        do {
            lines = try String(contentsOf: url).split(separator: "\n")
        } catch {
            throw PreconditionError(message: error.localizedDescription)
        }

        guard lines.count == 1 else {
            throw PreconditionError(message: """
The resolved_repositories_file must contain one line: the string to be used \
for the `RESOLVED_REPOSITORIES` build setting.
""")
        }

        return String(lines[0])
    }
}
