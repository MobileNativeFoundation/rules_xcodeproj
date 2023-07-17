import GeneratorCommon

extension Dictionary where Key: Comparable {
    public func value(for key: Key, context: String) throws -> Value {
        guard let value = self[key] else {
            throw PreconditionError(
                message: """
\(context) "\(key)" not found in:
\(keys.sorted())
"""
            )
        }
        return value
    }
}
