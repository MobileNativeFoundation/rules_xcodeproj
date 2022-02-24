import Darwin
import Foundation
import PathKit

@main
extension Generator {
    /// The entry point for the `generator` tool.
    static func main() {
        let logger = DefaultLogger()

        do {
            let arguments = try parseArguments(CommandLine.arguments)
            let rootDirs = try readRootDirectories(path: arguments.rootDirsPath)
            let project = try readProject(path: arguments.specPath)

            try Generator(logger: logger).generate(
                project: project,
                projectRootDirectory: rootDirs.projectRootDirectory,
                externalDirectory: rootDirs.externalDirectory,
                internalDirectoryName: "rules_xcodeproj",
                workspaceOutputPath: arguments.workspaceOutputPath,
                outputPath: arguments.outputPath
            )
        } catch {
            logger.logError(error.localizedDescription)
            exit(1)
        }
    }

    struct Arguments {
        let rootDirsPath: Path
        let specPath: Path
        let outputPath: Path
        let workspaceOutputPath: Path
    }

    static func parseArguments(_ arguments: [String]) throws -> Arguments {
        guard CommandLine.arguments.count == 5 else {
            throw UsageError(message: """
Usage: \(CommandLine.arguments[0]) <path/to/root_dirs_file> \
<path/to/project.json> <path/to/output/project.xcodeproj> \
<workspace/relative/output/path>
""")
        }

        return Arguments(
            rootDirsPath: Path(CommandLine.arguments[1]),
            specPath: Path(CommandLine.arguments[2]),
            outputPath: Path(CommandLine.arguments[3]),
            workspaceOutputPath: Path(CommandLine.arguments[4])
        )
    }

    struct RootDirectories {
        let projectRootDirectory: Path
        let externalDirectory: Path
    }

    static func readRootDirectories(path: Path) throws -> RootDirectories {
        let rootDirs = try path.read(.utf8)
            .split(separator: "\n")
            .map(String.init)

        guard rootDirs.count == 2 else {
            throw UsageError(message: """
The root_dirs_file must contain two lines, one for the source root and one for \
external repositories directory
""")
        }

        return RootDirectories(
            projectRootDirectory: Path(rootDirs[0]),
            externalDirectory: Path(rootDirs[1])
        )
    }

    static func readProject(path: Path) throws -> Project {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(Project.self, from: try path.read())
        } catch let error as DecodingError {
            // Return a more detailed error message
            throw PreconditionError(message: error.message)
        }
    }
}

private extension DecodingError {
    var message: String {
        guard let context = context else {
            return "An unknown decoding error occurred."
        }

        return """
At codingPath [\(context.codingPathString)]: \(context.debugDescription)
"""
    }

    private var context: Context? {
        switch self {
        case .typeMismatch(_, let context): return context
        case .valueNotFound(_, let context): return context
        case .keyNotFound(_, let context): return context
        case .dataCorrupted(let context): return context
        @unknown default: return nil
        }
    }
}

private extension DecodingError.Context {
    var codingPathString: String {
        print(codingPath)
        return codingPath.map(\.stringValue).joined(separator: ", ")
    }
}
