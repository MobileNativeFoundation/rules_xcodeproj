extension Optional {
    func orThrow(
        _ message: @autoclosure () -> String = "",
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) throws -> Wrapped {
        guard let value = self else {
            var errMsg = message()
            if errMsg == "" {
                errMsg = """
Expected non-nil value. (function: \(function), file: \(file), line: \(line))
"""
            }
            throw PreconditionError(message: errMsg)
        }
        return value
    }
}
