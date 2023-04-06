import Darwin
import Foundation
import PathKit
import ZippyJSON

@main
extension Generator {
    /// The entry point for the `generator` tool.
    static func main() async {
        let logger = DefaultLogger(
            standardError: StderrOutputStream(),
            standardOutput: StdoutOutputStream(),
            colorize: false
        )

        do {
            let rawArguments = CommandLine.arguments
            try self.validateNumberOfArguments(rawArguments)
            if self.shouldColorize(rawArguments) {
                logger.enableColors()
            }

            let arguments = try parseArguments(rawArguments)
            async let project = readProject(
                path: arguments.projectSpecPath,
                customXcodeSchemesPath: arguments.customXcodeSchemesPath,
                targetsPaths: arguments.targetsSpecPaths
            )
            async let executionRootDirectory = readExecutionRootDirectory(
                path: arguments.executionRootFilePath
            )
            async let xccurrentversions = readXCCurrentVersions(
                path: arguments.xccurrentversionsPath
            )
            async let extensionPointIdentifiers = readExtensionPointIdentifiers(
                path: arguments.extensionPointIdentifiersPath
            )
            let directories = try await Directories(
                workspace: arguments.workspaceDirectory,
                projectRoot: arguments.projectRootDirectory,
                executionRoot: executionRootDirectory,
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
        let customXcodeSchemesPath: Path
        let targetsSpecPaths: [Path]
        let executionRootFilePath: Path
        let workspaceDirectory: Path
        let xccurrentversionsPath: Path
        let extensionPointIdentifiersPath: Path
        let outputPath: Path
        let workspaceOutputPath: Path
        let projectRootDirectory: Path
        let buildMode: BuildMode
        let forFixtures: Bool
    }

    static func validateNumberOfArguments(_ arguments: [String]) throws {
        if arguments.count < 13 {
            throw UsageError(message: """
Usage: \(arguments[0]) <path/to/execution_root_file> <workspace_directory> \
<path/to/xccurrentversions.json> <path/to/extensionPointIdentifiers.json> \
<path/to/output/project.xcodeproj> <workspace/relative/output/path> \
(xcode|bazel) <1 is for fixtures, otherwise 0> <1 is to enable colors in logs, otherwise 0> \
<path/to/project_spec.json> <path/to/custom_xcode_schemes.json> [<path/to/targets_spec.json>, ...]
""")
        }
    }

    static func shouldColorize(_ arguments: [String]) -> Bool {
        arguments[9] == "1"
    }

    static func parseArguments(_ arguments: [String]) throws -> Arguments {
        let workspaceOutput = arguments[6]
        let workspaceOutputComponents = workspaceOutput.split(separator: "/")

        // Generate a relative path to the project root
        // e.g. "examples/ios/iOS App.xcodeproj" -> "../.."
        // e.g. "project.xcodeproj" -> ""
        let projectRoot = (0 ..< (workspaceOutputComponents.count - 1))
            .map { _ in ".." }
            .joined(separator: "/")

        guard
            let buildMode = BuildMode(rawValue: arguments[7])
        else {
            throw UsageError(message: """
ERROR: build_mode wasn't one of the supported values: xcode, bazel
""")
        }

        return Arguments(
            projectSpecPath: Path(arguments[10]),
            customXcodeSchemesPath: Path(arguments[11]),
            targetsSpecPaths: arguments.suffix(from: 12).map { Path($0) },
            executionRootFilePath: Path(arguments[1]),
            workspaceDirectory: Path(arguments[2]),
            xccurrentversionsPath: Path(arguments[3]),
            extensionPointIdentifiersPath: Path(arguments[4]),
            outputPath: Path(arguments[5]),
            workspaceOutputPath: Path(workspaceOutput),
            projectRootDirectory: Path(projectRoot),
            buildMode: buildMode,
            forFixtures: arguments[8] == "1"
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
                return try decoder.decode(type, from: path.read())
            } catch let error as DecodingError {
                // Return a more detailed error message
                throw PreconditionError(message: """
Error decoding "\(path)":
\(error.message)
""")
            }
        }.value
    }

    static func readProject(
        path: Path,
        customXcodeSchemesPath: Path,
        targetsPaths: [Path]
    ) async throws -> Project {
        async let targets: [TargetID: Target] = withThrowingTaskGroup(
            of: [TargetID: Target].self
        ) { group in
            var targets: [TargetID: Target] = [:]

            for path in targetsPaths {
                group.addTask {
                    try await decodeJSON(
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

        async let customXcodeSchemes = decodeJSON(
            [XcodeScheme].self,
            from: customXcodeSchemesPath
        )

        var project = try await decodeJSON(Project.self, from: path)
        project.targets = try await targets
        project.customXcodeSchemes = try await customXcodeSchemes
        return project
    }

    static func readExecutionRootDirectory(path: Path) async throws -> Path {
        return try await Task {
            let executionRoot = try path.read(.utf8)
                .split(separator: "\n")
                .map(String.init)

            guard executionRoot.count == 1 else {
                throw PreconditionError(message: """
The execution_root_file must contain one line: the execution root directory.
""")
            }

            return Path(executionRoot[0])
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
