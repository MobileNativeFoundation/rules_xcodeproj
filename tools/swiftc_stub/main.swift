import Foundation
import OrderedCollections

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

func findPath(key: String, from args: OrderedSet<String>) -> URL? {
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

func isWMO(args: OrderedSet<String>) -> Bool {
    return args.contains("-wmo") || args.contains("-whole-module-optimization")
}

/// Touch the Xcode-required .d files
func touchDepsFiles(_ args: OrderedSet<String>) throws {
    guard let outputFileMapPath = findPath(key: "-output-file-map", from: args)
    else { return }

    if isWMO(args: args) {
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

/// Touch the Xcode-required .swift{module,doc,sourceinfo} files"
func touchSwiftmoduleArtifacts(_ args: OrderedSet<String>) throws {
    if var swiftmodulePath = findPath(key: "-emit-module-path", from: args) {
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

    if var generatedHeaderPath = findPath(
        key: "-emit-objc-header-path",
        from: args
    ) {
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

func handleSwiftUIPreviewThunk(_ args: OrderedSet<String>) throws {
    guard let sdkPath = findPath(key: "-sdk", from: args)?.path
    else {
        print("warning: No such argument '-sdk'")
        exit(try runSubProcess(
            executable: "swiftc",
            args: Array(args.dropFirst())
        ))
    }

    // TODO: Make this work with custom toolchains
    // We could produce this file at the start of the build?
    let fullRange = NSRange(sdkPath.startIndex..., in: sdkPath)
    let matches = try NSRegularExpression(
        pattern: #".*?/Contents/Developer)/.*"#
    ).matches(in: sdkPath, range: fullRange)
    guard let developerDir = matches.first else {
        print("warning: Failed to parse DEVELOPER_DIR from '-sdk'")
        exit(try runSubProcess(
            executable: "swiftc",
            args: Array(args.dropFirst())
        ))
    }

    exit(try runSubProcess(
        executable: """
\(developerDir)/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
""",
        args: Array(args.dropFirst())
    ))
}

// MARK: - Main

let args = OrderedSet(CommandLine.arguments)

if args.count == 2, args.last == "-v" {
    exit(try runSubProcess(executable: "swiftc", args: ["-v"]))
}

for arg in args {
    if arg.hasSuffix(".preview-thunk.swift"), args.contains("-output-file-map")
    {
        // Pass through for SwiftUI Preview thunk compilation
        try handleSwiftUIPreviewThunk(args)
    }
}

try touchDepsFiles(args)
try touchSwiftmoduleArtifacts(args)
