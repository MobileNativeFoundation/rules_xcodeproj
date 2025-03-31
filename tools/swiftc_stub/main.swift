// #!/usr/bin/env swift

import Foundation

// Log command and arguments
let logMessage = """
\(CommandLine.arguments.joined(separator: " "))
"""
try logMessage.appendLineToURL(fileURL: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("rulesxcodeproj_ld.log"))

extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }

    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } else {
            try self.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        }
    }
}

// MARK: - Helpers

enum PathKey: String {
    case emitModulePath = "-emit-module-path"
    case emitModuleSourceInfoPath = "-emit-module-source-info-path"
    case emitDependenciesPath = "-emit-dependencies-path"
    case emitABIDescriptorPath = "-emit-abi-descriptor-path"
    case emitModuleDocPath = "-emit-module-doc-path"
    case outputFileMap = "-output-file-map"
    case sdk = "-sdk"
}

func processArgs(
    _ args: [String]
) async throws -> (
    isPreviewThunk: Bool,
    isWMO: Bool,
    paths: [PathKey: [URL]]
) {
    var isPreviewThunk = false
    var isWMO = false
    var paths: [PathKey: [URL]] = [:]

    var previousArg: String?
    func processArg(_ arg: String) throws{
        if let rawPathKey = previousArg,
            let key = PathKey(rawValue: rawPathKey)
        {
            let url = URL(fileURLWithPath: arg)
            if paths[key] != nil {
                paths[key]?.append(url)
            } else {
                paths[key] = [url]
            }
            previousArg = nil
            return
        }

        if arg == "-wmo" || arg == "-whole-module-optimization" {
            isWMO = true
        } else if arg.hasSuffix(".preview-thunk.o") {
            try "isPreviewThunk".appendLineToURL(fileURL: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("rulesxcodeproj_ld.log"))
            isPreviewThunk = true
        } else {
            previousArg = arg
        }
    }

    for arg in args {
        if arg.hasPrefix("@") {
            let argumentFileURL
                = URL(fileURLWithPath: String(arg.dropFirst()))
            for try await line in argumentFileURL.lines {
                if line.hasPrefix(#"""#) && line.hasSuffix(#"""#) {
                    try processArg(String(line.dropFirst().dropLast()))
                } else {
                    try processArg(String(line))
                }
            }
        } else {
            try processArg(arg)
        }
    }

    return (
        !paths.keys.contains(.outputFileMap) && isPreviewThunk,
        isWMO,
        paths
    )
}

extension URL {
    mutating func touch() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            fileManager.createFile(atPath: path, contents: nil)
        } else {
            var resourceValues = URLResourceValues()
            resourceValues.contentModificationDate = Date()
            try setResourceValues(resourceValues)
        }
    }
}

extension Array where Element == URL {
    mutating func touch() throws {
        for var url in self {
            try url.touch()
        }
    }
}

/// Touch the Xcode-required `.d` and `-master-emit-module.d` files
func touchDepsFiles(isWMO: Bool, paths: [PathKey: [URL]]) throws {
    guard let outputFileMapPaths = paths[PathKey.outputFileMap], let outputFileMapPath = outputFileMapPaths.first else { return }

    if isWMO {
        let pathNoExtension = String(outputFileMapPath.path.dropLast("-OutputFileMap.json".count))
        var masterDFilePath = URL(fileURLWithPath: pathNoExtension + "-master.d")
        try masterDFilePath.touch()
    } else {
        let data = try Data(contentsOf: outputFileMapPath)
        let outputFileMapRaw = try JSONSerialization.jsonObject(
            with: data,
            options: []
        )
        guard let outputFileMap = outputFileMapRaw as? [String: [String: Any]]
        else {
            return
        }

        for entry in outputFileMap.values {
            if let dPath = entry["dependencies"] as? String {
                var url = URL(fileURLWithPath: dPath)
                try url.touch()
            }
            continue
        }
    }
}

/// Touch the Xcode-required `-master-emit-module.d`, `.{d,abi.json}` and `.swift{module,doc,sourceinfo}` files
func touchSwiftmoduleArtifacts(paths: [PathKey: [URL]]) throws {
    if let swiftmodulePaths = paths[PathKey.emitModulePath] {
        for var swiftmodulePath in swiftmodulePaths {
            let pathNoExtension = swiftmodulePath.deletingPathExtension()
            var swiftdocPath = pathNoExtension
                .appendingPathExtension("swiftdoc")
            var swiftsourceinfoPath = pathNoExtension
                .appendingPathExtension("swiftsourceinfo")
            var swiftinterfacePath = pathNoExtension
                .appendingPathExtension("swiftinterface")

            try swiftmodulePath.touch()
            try swiftdocPath.touch()
            try swiftsourceinfoPath.touch()
            try swiftinterfacePath.touch()
        }
    }

    if var modulePaths = paths[PathKey.emitModuleSourceInfoPath] {
        try modulePaths.touch()
    }

    if var dependencyPaths = paths[PathKey.emitDependenciesPath] {
        try dependencyPaths.touch()
    }

    if var abiPaths = paths[PathKey.emitABIDescriptorPath] {
        try abiPaths.touch()
    }

    if let docPaths = paths[PathKey.emitModuleDocPath] {
        for var path in docPaths {
            var swiftModulePath = path.deletingPathExtension()
                .appendingPathExtension("swiftmodule")
            try swiftModulePath.touch()
            try path.touch()
        }
    }
}

func runSubProcess(executable: String, args: [String]) throws -> Int32 {
    let task = Process()
    task.launchPath = executable
    task.arguments = args
    try task.run()
    task.waitUntilExit()
    return task.terminationStatus
}

func handleXcodePreviewThunk(args: [String], paths: [PathKey: [URL]]) throws -> Never {
    guard let sdkPath = paths[PathKey.sdk]?.first?.path else {
        fputs(
            "error: No such argument '-sdk'. Using /usr/bin/swiftc.",
            stderr
        )
        exit(1)
    }

    // TODO: Make this work with custom toolchains
    // We could produce this file at the start of the build?
    let fullRange = NSRange(sdkPath.startIndex..., in: sdkPath)
    let matches = try NSRegularExpression(
        pattern: #"(.*?/Contents/Developer)/.*"#
    ).matches(in: sdkPath, range: fullRange)
    guard let match = matches.first,
        let range = Range(match.range(at: 1), in: sdkPath)
    else {
        fputs(
            """
error: Failed to parse DEVELOPER_DIR from '-sdk'. Using /usr/bin/swiftc.
""",
            stderr
        )
        exit(1)
    }
    let developerDir = sdkPath[range]

    let processedArgs = args.dropFirst().map { arg in
        if let range = arg.range(of: "BazelRulesXcodeProj") {
            let substring = arg[..<range.lowerBound]
            // Extract the version suffix (e.g. "16B40" from "BazelRulesXcodeProj16B40")
            let toolchainSuffix = arg[range.upperBound...].prefix(while: { $0 != "." })
            return arg.replacingOccurrences(
                of: String(substring) + "BazelRulesXcodeProj" + toolchainSuffix + ".xctoolchain",
                with: "\(developerDir)/Toolchains/XcodeDefault.xctoolchain"
            )
        }
        return arg
    }
    try exit(runSubProcess(
        executable: """
\(developerDir)/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
""",
        args: Array(processedArgs)
    ))
}

// MARK: - Main

let args = CommandLine.arguments
// Xcode 16.0 Beta 3 began using "--version" over "-v". Support both.
if args.count == 2, args.last == "--version" || args.last == "-v" {
    guard let path = ProcessInfo.processInfo.environment["PATH"] else {
        fputs("error: PATH not set", stderr)
        exit(1)
    }

    // /Applications/Xcode-15.0.0-Beta.app/Contents/Developer/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin -> /Applications/Xcode-15.0.0-Beta.app/Contents/Developer/usr/bin
    let pathComponents = path.split(separator: ":", maxSplits: 1)
    let xcodeBinPath = pathComponents[0]
    guard xcodeBinPath.hasSuffix("/Contents/Developer/usr/bin") else {
        fputs("error: Xcode based bin PATH not set", stderr)
        exit(1)
    }

    // /Applications/Xcode-15.0.0-Beta.app/Contents/Developer/usr/bin -> /Applications/Xcode-15.0.0-Beta.app/Contents/Developer
    let developerDir = xcodeBinPath.dropLast(8)

    // TODO: Make this work with custom toolchains
    let swiftcPath = """
\(developerDir)/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
"""

    // args.last allows passing in -v (Xcode < 16b3) and --version (>= 16b3)
    try exit(runSubProcess(executable: swiftcPath, args: [args.last!]))
}

let (
    isPreviewThunk,
    isWMO,
    paths
) = try await processArgs(args)

guard !isPreviewThunk else {
    // Pass through for Xcode Preview thunk compilation
    try handleXcodePreviewThunk(args: args, paths: paths)
}

try touchDepsFiles(isWMO: isWMO, paths: paths)
try touchSwiftmoduleArtifacts(paths: paths)
