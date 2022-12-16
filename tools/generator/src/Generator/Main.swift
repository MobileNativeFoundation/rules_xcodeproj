import Darwin
import Foundation
import ZippyJSON
import PathKit

@main
extension Generator {
    /// The entry point for the `generator` tool.
    static func main() async {
        let logger = DefaultLogger()

        do {
            let arguments = try parseArguments(CommandLine.arguments)
            async let project = readProject(
                path: arguments.projectSpecPath,
                targetsPaths: arguments.targetsSpecPaths
            )
            async let rootDirs = readRootDirectories(
                path: arguments.rootDirsPath
            )
            async let xccurrentversions = readXCCurrentVersions(
                path: arguments.xccurrentversionsPath
            )
            async let extensionPointIdentifiers = readExtensionPointIdentifiers(
                path: arguments.extensionPointIdentifiersPath
            )
            let directories = try await Directories(
                workspace: rootDirs.workspaceDirectory,
                projectRoot: arguments.projectRootDirectory,
                external: rootDirs.externalDirectory,
                bazelOut: rootDirs.bazelOutDirectory,
                internalDirectoryName: "rules_xcodeproj",
                workspaceOutput: arguments.workspaceOutputPath
            )

            try await Generator(logger: logger).generate(
                buildMode: arguments.buildMode,
                forFixtures: arguments.forFixtures,
                project: project,
                xccurrentversions: xccurrentversions,
                extensionPointIdentifiers: extensionPointIdentifiers,
                directories: directories,
                outputPath: arguments.outputPath
            )
        } catch {
            logger.logError(error.localizedDescription)
            exit(1)
        }
    }

    struct Arguments {
        let projectSpecPath: Path
        let targetsSpecPaths: [Path]
        let rootDirsPath: Path
        let xccurrentversionsPath: Path
        let extensionPointIdentifiersPath: Path
        let outputPath: Path
        let workspaceOutputPath: Path
        let projectRootDirectory: Path
        let buildMode: BuildMode
        let forFixtures: Bool
    }

    static func parseArguments(_ arguments: [String]) throws -> Arguments {
        guard arguments.count >= 10 else {
            throw UsageError(message: """
Usage: \(arguments[0]) <path/to/root_dirs> \
<path/to/xccurrentversions.json> <path/to/extensionPointIdentifiers.json> \
<path/to/output/project.xcodeproj> <workspace/relative/output/path> \
(xcode|bazel) <1 is for fixtures, otherwise 0> <path/to/project_spec.json> \
[<path/to/targets_spec.json>, ...]
""")
        }

        let workspaceOutput = arguments[5]
        let workspaceOutputComponents = workspaceOutput.split(separator: "/")

        // Generate a relative path to the project root
        // e.g. "examples/ios/iOS App.xcodeproj" -> "../.."
        // e.g. "project.xcodeproj" -> ""
        let projectRoot = (0 ..< (workspaceOutputComponents.count - 1))
            .map { _ in ".." }
            .joined(separator: "/")

        guard
            let buildMode = BuildMode(rawValue: arguments[6])
        else {
            throw UsageError(message: """
ERROR: build_mode wasn't one of the supported values: xcode, bazel
""")
        }

        return Arguments(
            projectSpecPath: Path(arguments[8]),
            targetsSpecPaths: arguments.suffix(from: 9).map { Path($0) },
            rootDirsPath: Path(arguments[1]),
            xccurrentversionsPath: Path(arguments[2]),
            extensionPointIdentifiersPath: Path(arguments[3]),
            outputPath: Path(arguments[4]),
            workspaceOutputPath: Path(workspaceOutput),
            projectRootDirectory: Path(projectRoot),
            buildMode: buildMode,
            forFixtures: arguments[7] == "1"
        )
    }

    static func decodeJSON<T: Decodable>(
        _ type: T.Type,
        from path: Path
    ) async throws -> T {
        return try await Task {
            do {
                let decoder = ZippyJSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(type, from: try path.read())
            } catch let error as DecodingError {
                // Return a more detailed error message
                throw PreconditionError(message: error.message)
            }
        }.value
    }

    static func readProject(
        path: Path,
        targetsPaths: [Path]
    ) async throws -> Project {
        async let targets: [TargetID: Target] = withThrowingTaskGroup(
            of: [TargetID: Target].self
        ) { group in
            var targets: [TargetID: Target] = [:]

            for path in targetsPaths {
                group.addTask {
                    return try await decodeJSON(
                        [TargetID: Target].self,
                        from: path
                    )
                }
            }

            for try await targetsSlice in group {
                try targets.merge(targetsSlice) { _, new in
                    throw PreconditionError(message: """
Duplicate target (\(new.label) \(new.configuration) in target specs
""")
                }
            }

            return targets
        }

        var project = try await decodeJSON(Project.self, from: path)
        project.targets = try await targets
        return project
    }

    struct RootDirectories {
        let workspaceDirectory: Path
        let externalDirectory: Path
        let bazelOutDirectory: Path
    }

    static func readRootDirectories(
        path: Path
    ) async throws -> RootDirectories {
        return try await Task {
            let rootDirs = try path.read(.utf8)
                .split(separator: "\n")
                .map(String.init)

            guard rootDirs.count == 3 else {
                throw UsageError(message: """
The root_dirs_file must contain three lines: one for the workspace directory, \
one for the external repositories directory, and one for the bazel-out \
directory.
""")
            }

            return RootDirectories(
                workspaceDirectory: Path(rootDirs[0]),
                externalDirectory: Path(rootDirs[1]),
                bazelOutDirectory: Path(rootDirs[2])
            )
        }.value
    }

    static func readXCCurrentVersions(
        path: Path
    ) async throws -> [XCCurrentVersion] {
        return try await decodeJSON(
            [XCCurrentVersion].self,
            from: path
        )
    }

    static func readExtensionPointIdentifiers(
        path: Path
    ) async throws -> [TargetID: ExtensionPointIdentifier] {
        return try await decodeJSON(
            [TargetID: ExtensionPointIdentifier].self,
            from: path
        )
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
        case let .typeMismatch(_, context): return context
        case let .valueNotFound(_, context): return context
        case let .keyNotFound(_, context): return context
        case let .dataCorrupted(context): return context
        @unknown default: return nil
        }
    }
}

private extension DecodingError.Context {
    var codingPathString: String {
        return codingPath.map(\.stringValue).joined(separator: ", ")
    }
}
