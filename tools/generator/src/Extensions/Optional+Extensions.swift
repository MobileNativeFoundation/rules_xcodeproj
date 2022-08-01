extension Optional {
    func orThrow(_ message: @autoclosure () -> String) throws -> Wrapped {
        guard let value = self else {
            throw PreconditionError(message: message())
        }
        return value
    }
}
