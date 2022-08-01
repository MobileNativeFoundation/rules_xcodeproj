extension Dictionary {
    /// Look up a value using the key. Throw an error if it is not found.
    func value(
        for key: Key,
        context: @autoclosure () -> String = "",
        message: @autoclosure () -> String = ""
    ) throws -> Value {
        return try self[key].orThrow({
            let userMessage = message()
            guard userMessage != "" else {
                let contextStr = context()
                let endOfMsg = contextStr.isEmpty ? "" : ", while \(contextStr)"
                return """
Unable to find the `\(Value.self)` for the `\(Key.self)`, "\(key)"\(endOfMsg).
"""
            }
            return userMessage
        }())
    }
}
