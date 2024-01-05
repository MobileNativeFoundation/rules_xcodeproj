import Foundation

@discardableResult func runSubProcess(
    _ executable: String,
    _ args: [String],
    ignoreStdErr: Bool = false
) throws -> Int32 {
    let task = Process()
    task.launchPath = executable
    task.arguments = args

    if ignoreStdErr {
        task.standardError = Pipe()
    }

    try task.run()
    task.waitUntilExit()

    return task.terminationStatus
}
