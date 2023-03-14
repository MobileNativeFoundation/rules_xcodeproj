extension Array where Element == String {
    static let validCommandLineArgSuffix: String = "--command_line_args="

    func extractCommandLineArguments() -> [String] {
        return flatMap { arg -> [String] in
            guard arg.hasPrefix(Array.validCommandLineArgSuffix)
            else {
                return []
            }
            return String(arg.dropFirst(Array.validCommandLineArgSuffix.count)).components(separatedBy: ",")
        }
    }
}
