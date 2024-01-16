import Foundation

@discardableResult func runSubProcess(
    currentDirectoryURL: URL? = nil,
    _ executable: String,
    _ args: [String]
) throws -> (output: String, errorOutput: String, exitCode: Int32) {
    let task = Process()
    task.currentDirectoryURL = currentDirectoryURL
    task.launchPath = executable
    task.arguments = args

    let standardOutput = Pipe()
    task.standardOutput = standardOutput

    let standardError = Pipe()
    task.standardError = standardError

    try task.run()
    task.waitUntilExit()

    return (
        String(
            data: standardOutput.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )!,
        String(
            data: standardError.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )!,
        task.terminationStatus
    )
}
