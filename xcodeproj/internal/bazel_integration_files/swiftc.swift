import Foundation

// MARK: - Helpers

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

func findPath(key: String, from args: [String]) -> URL? {
    var found = false
    for arg in args {
        if found {
            return URL(fileURLWithPath: arg)
        }
        if arg == key {
            found = true
        }
    }
    return nil
}

/// Touch the Xcode-required .d files
func touchDepsFiles(_ args: [String]) throws {
    guard let outputFileMapPath = findPath(key: "-output-file-map", from: args)
    else { return }

    let dFile = String(outputFileMapPath.path.dropLast("-OutputFileMap.json".count) + "-master.d")
    var url = URL(fileURLWithPath: dFile)
    try url.touch()
}

/// Touch the Xcode-required .d files
func touchSwiftmoduleArtifacts(_ args: [String]) throws {
    if var swiftmodulePath = findPath(key: "-emit-module-path", from: args) {
        var swiftdocPath = swiftmodulePath.deletingPathExtension().appendingPathExtension("swiftdoc")
        var swiftsourceinfoPath = swiftmodulePath.deletingPathExtension().appendingPathExtension("swiftsourceinfo")
        var swiftinterfacePath = swiftmodulePath.deletingPathExtension().appendingPathExtension("swiftinterface")

        try swiftmodulePath.touch()
        try swiftdocPath.touch()
        try swiftsourceinfoPath.touch()
        try swiftinterfacePath.touch()
    }

    if var generatedHeaderPath = findPath(key: "-emit-objc-header-path", from: args) {
        try generatedHeaderPath.touch()
    }
}

func runSubProcess(args: [String]) throws -> Int32 {
    let task = Process()
    task.launchPath = args.first
    task.arguments = Array(args.dropFirst())
    try task.run()
    task.waitUntilExit()
    return task.terminationStatus
}

// MARK: - Main

let args = CommandLine.arguments

if args.count == 1, args.last == "-v" {
    exit(try runSubProcess(args: ["swiftc", "-v"]))
}

for arg in args {
    // Pass through for SwiftUI Preview thunk compilation
    if arg.hasSuffix(".preview-thunk.swift"), args.contains("-output-file-map") {
        guard let sdkPath = findPath(key: "-sdk", from: args)?.path else { break }
        let fullRange = NSRange(sdkPath.startIndex..., in: sdkPath)
        let matches = try NSRegularExpression(pattern: #".*?/Contents/Developer)/.*"#)
            .matches(in: sdkPath, range: fullRange)
        guard let developerDir = matches.first else { break }
        let swiftc = "\(developerDir)/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
        exit(try runSubProcess(args: [swiftc] + args.dropFirst()))
    }

    try touchDepsFiles(args)
    try touchSwiftmoduleArtifacts(args)
}
