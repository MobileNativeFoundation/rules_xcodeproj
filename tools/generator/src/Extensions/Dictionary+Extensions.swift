extension Dictionary {
    /// Look up a value using the key. Throw an error if it is not found.
    func value(
        for key: Key,
        context: @autoclosure () -> String = ""
    ) throws -> Value {
        guard let value = self[key] else {
            let contextStr = context()
            let endOfMsg = contextStr.isEmpty ? "" : ", while \(contextStr)"
            throw PreconditionError(message: """
Unable to find the `\(Value.self)` for the `\(Key.self)`, "\(key)"\(endOfMsg).
""")
        }
        return value
    }
}
