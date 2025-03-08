import Foundation

// MARK: - Helpers

enum PathKey: String {
    case emitModulePath = "-emit-module-path"
    case emitObjCHeaderPath = "-emit-objc-header-path"
    case outputFileMap = "-output-file-map"
    case sdk = "-sdk"
}

func processArgs(
    _ args: [String]
) async throws -> (
    isPreviewThunk: Bool,
    isWMO: Bool,
    paths: [PathKey: URL]
) {
    var isPreviewThunk = false
    var isWMO = false
    var paths: [PathKey: URL] = [:]

    var previousArg: String?
    func processArg(_ arg: String) {
        if let rawPathKey = previousArg,
            let key = PathKey(rawValue: rawPathKey)
        {
            paths[key] = URL(fileURLWithPath: arg)
            previousArg = nil
            return
        }

        if arg == "-wmo" || arg == "-whole-module-optimization" {
            isWMO = true
        } else if arg.hasSuffix(".preview-thunk.swift") {
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
                    processArg(String(line.dropFirst().dropLast()))
                } else {
                    processArg(String(line))
                }
            }
        } else {
            processArg(arg)
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

/// Touch the Xcode-required `.d` files
func touchDepsFiles(isWMO: Bool, paths: [PathKey: URL]) throws {
    guard let outputFileMapPath = paths[PathKey.outputFileMap] else { return }

    if isWMO {
        let dPath = String(
            outputFileMapPath.path.dropLast("-OutputFileMap.json".count) +
            "-master.d"
        )
        var url = URL(fileURLWithPath: dPath)
        try url.touch()
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
            guard let dPath = entry["dependencies"] as? String else {
                continue
            }
            var url = URL(fileURLWithPath: dPath)
            try url.touch()
        }
    }
}

/// Touch the Xcode-required `.swift{module,doc,sourceinfo}` files
func touchSwiftmoduleArtifacts(paths: [PathKey: URL]) throws {
    if var swiftmodulePath = paths[PathKey.emitModulePath] {
        var swiftdocPath = swiftmodulePath.deletingPathExtension()
            .appendingPathExtension("swiftdoc")
        var swiftsourceinfoPath = swiftmodulePath.deletingPathExtension()
            .appendingPathExtension("swiftsourceinfo")
        var swiftinterfacePath = swiftmodulePath.deletingPathExtension()
            .appendingPathExtension("swiftinterface")

        try swiftmodulePath.touch()
        try swiftdocPath.touch()
        try swiftsourceinfoPath.touch()
        try swiftinterfacePath.touch()
    }

    if var generatedHeaderPath = paths[PathKey.emitObjCHeaderPath] {
        try generatedHeaderPath.touch()
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

func handleXcodePreviewThunk(args: [String], paths: [PathKey: URL]) throws -> Never {
    var swiftcPath: String?

    if let toolchainDir = ProcessInfo.processInfo.environment["TOOLCHAIN_DIR"] {
        swiftcPath = "\(toolchainDir)/usr/bin/swiftc"
    } else {
        guard let sdkPath = paths[PathKey.sdk]?.path else {
            fputs("error: No such argument '-sdk'. Using /usr/bin/swiftc.", stderr)
            exit(1)
        }

        // We could produce this file at the start of the build?
        let fullRange = NSRange(sdkPath.startIndex..., in: sdkPath)
        let matches = try NSRegularExpression(
            pattern: #"(.*?/Contents/Developer)/.*"#
        ).matches(in: sdkPath, range: fullRange)
        guard let match = matches.first,
            let range = Range(match.range(at: 1), in: sdkPath)
        else {
            fputs("error: Failed to parse DEVELOPER_DIR from '-sdk'. Using /usr/bin/swiftc.", stderr)
            exit(1)
        }
        let developerDir = sdkPath[range]

        swiftcPath = "\(developerDir)/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
    }

    guard let swiftcPath else {
        fputs("error: Failed to determine swiftc path", stderr)
        exit(1)
    }

    try exit(runSubProcess(executable: swiftcPath, args: Array(args.dropFirst())))
}

// MARK: - Main

let args = CommandLine.arguments
// Xcode 16.0 Beta 3 began using "--version" over "-v". Support both.
if args.count == 2, args.last == "--version" || args.last == "-v" {
    guard let path = ProcessInfo.processInfo.environment["PATH"] else {
        fputs("error: PATH not set", stderr)
        exit(1)
    }

    var swiftcPath: String?
    
    if let toolchainDir = ProcessInfo.processInfo.environment["TOOLCHAIN_DIR"] {
        swiftcPath = """
        \(toolchainDir)/usr/bin/swiftc
        """
    } else {
        // /Applications/Xcode-15.0.0-Beta.app/Contents/Developer/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin -> /Applications/Xcode-15.0.0-Beta.app/Contents/Developer/usr/bin
        let pathComponents = path.split(separator: ":", maxSplits: 1)
        let xcodeBinPath = pathComponents[0]
        guard xcodeBinPath.hasSuffix("/Contents/Developer/usr/bin") else {
            fputs("error: Xcode based bin PATH not set", stderr)
            exit(1)
        }
        // /Applications/Xcode-15.0.0-Beta.app/Contents/Developer/usr/bin -> /Applications/Xcode-15.0.0-Beta.app/Contents/Developer
        let developerDir = xcodeBinPath.dropLast(8)
        swiftcPath = """
        \(developerDir)/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
        """
    }

    guard let swiftcPath else {
        fputs("error: Failed to determine swiftc path", stderr)
        exit(1)
    }

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
