import Foundation
import ToolCommon

@main
struct ImportIndex {
    static func main() async throws {
        do {
            let args = CommandLine.arguments
            let pidFile =
            try getEnvironmentVariable("OBJROOT") + "/import_indexstores.pid"

            guard args.count > 1 else {
                throw PreconditionError(message: """
Not enough arguments, expected path to execution root
"""
                )
            }
            let buildExecutionRoot = args[1]

            // Exit early if no indexstore filelists were provided
            if args.count == 2 {
                return
            }

            // MARK: pidFile

            // Kill any previously running import
            if FileManager.default.fileExists(atPath: pidFile) {
                let pid = try String(contentsOfFile: pidFile)

                try runSubProcess("/bin/kill", [pid])
                while true {
                    if try runSubProcess("/bin/kill", ["-0", pid]) != 0 {
                        break
                    }
                    sleep(1)
                }
            }

            // Set pid to allow cleanup later
            try String(ProcessInfo.processInfo.processIdentifier)
                .write(toFile: pidFile, atomically: true, encoding: .utf8)
            defer {
                try? FileManager.default.removeItem(atPath: pidFile)
            }

            // MARK: filelist

            let projectDirPrefix =
                try getEnvironmentVariable("PROJECT_DIR") + "/"

            // Merge all filelists into a single file
            var indexstores: [String: Set<String>] = [:]
            for filePath in args.dropFirst(2) {
                let url = URL(fileURLWithPath: filePath)

                var iterator = url.allLines.makeAsyncIterator()
                while let indexstore = try await iterator.next() {
                    guard let targetPathOverride = try await iterator.next()
                    else {
                        throw PreconditionError(message: """
indexstore filelists must contain pairs of <indexstore> <target-path-override> \
lines
"""
                        )
                    }

                    indexstores[targetPathOverride, default: []]
                        .insert(indexstore)
                }
            }

            // Exit early if no indexstores were provided
            guard !indexstores.isEmpty else {
                return
            }

            let indexDataStoreDir = URL(
                fileURLWithPath:
                    try getEnvironmentVariable("INDEX_DATA_STORE_DIR")
            )
            let recordsDir =
                indexDataStoreDir.appendingPathComponent("v5/records")

            try FileManager.default.createDirectory(
                at: recordsDir,
                withIntermediateDirectories: true
            )

            // We remove any `/private` prefix from the current execution_root,
            // since it's removed in the Project navigator
            let xcodeExecutionRoot: String
            if buildExecutionRoot.hasPrefix("/private") {
                xcodeExecutionRoot = String(buildExecutionRoot.dropFirst(8))
            } else {
                xcodeExecutionRoot = buildExecutionRoot
            }

            let projectTempDir = try getEnvironmentVariable("PROJECT_TEMP_DIR")

            let objectFilePrefix: String
            if try getEnvironmentVariable("ACTION") == "indexbuild" {
                // Remove `Index.noindex/` part of path
                objectFilePrefix = projectTempDir.replacingOccurrences(
                    of: "/Index.noindex/Build/Intermediates.noindex/",
                    with: "/Build/Intermediates.noindex/"
                )
            } else {
                // Remove Xcode Previews part of path
                objectFilePrefix = try projectTempDir.replacingRegex(
                    matching: #"""
Intermediates\.noindex/Previews/[^/]*/Intermediates\.noindex
"""#,
                    with: "Intermediates.noindex"
                )
            }

            let xcodeOutputBase = xcodeExecutionRoot
                .split(separator: "/")
                .dropLast(2)
                .joined(separator: "/")

            let archs = try getEnvironmentVariable("ARCHS")
            let arch = String(archs.split(separator: " ", maxSplits: 1).first!)

            let developerDir = try getEnvironmentVariable("DEVELOPER_DIR")
            let indexImport = try getEnvironmentVariable("INDEX_IMPORT")
            let srcRoot = try getEnvironmentVariable("SRCROOT")

            try await withThrowingTaskGroup(of: Void.self) { group in
                for (targetPathOverride, indexstores) in indexstores {
                    group.addTask {
                        try Self.import(
                            indexstores,
                            into: indexDataStoreDir,
                            arch: arch,
                            developerDir: developerDir,
                            indexImport: indexImport,
                            objectFilePrefix: objectFilePrefix,
                            projectDirPrefix: projectDirPrefix,
                            srcRoot: srcRoot,
                            targetPathOverride:
                                targetPathOverride.isEmpty ?
                                    nil : targetPathOverride,
                            xcodeExecutionRoot: xcodeExecutionRoot,
                            xcodeOutputBase: xcodeOutputBase
                        )
                    }
                }

                try await group.waitForAll()
            }

            // Unit files are created fresh, but record files are copied from
            // `bazel-out/`, which are read-only. We need to adjust their
            // permissions.
            // TODO: do this in `index-import`
            try setWritePermissions(in: recordsDir)
        } catch {
            fputs(error.localizedDescription, stderr)
            Darwin.exit(1)
        }
    }
}

private func getEnvironmentVariable(
    _ key: String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> String {
    guard let value = ProcessInfo.processInfo.environment[key] else {
        throw PreconditionError(
            message: #"Environment variable "\#(key)" not set"#,
            file: file,
            line: line
        )
    }
    guard !value.isEmpty else {
        throw PreconditionError(
            message: #"""
Environment variable "\#(key)" is set to an empty string
"""#,
            file: file,
            line: line
        )
    }
    return value
}

private func setWritePermissions(in url: URL) throws {
    let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.isDirectoryKey]
    )!
    for case let url as URL in enumerator {
        let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
        if resourceValues.isDirectory! {
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: url.path
            )
        } else {
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o644],
                ofItemAtPath: url.path
            )
        }
    }
}

extension String {
    func replacingRegex(
        matching pattern: String,
        with template: String
    ) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(startIndex..., in: self)
        return regex.stringByReplacingMatches(
            in: self,
            range: range,
            withTemplate: template
        )
    }
 }
