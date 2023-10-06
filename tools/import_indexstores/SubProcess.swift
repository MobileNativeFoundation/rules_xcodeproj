import Foundation

@discardableResult func runSubProcess(
    _ executable: String,
    _ args: [String]
) throws -> Int32 {
    let task = Process()
    task.launchPath = executable
    task.arguments = args
    try task.run()
    task.waitUntilExit()
    return task.terminationStatus
}
