import GeneratorCommon

extension Dictionary where Key: Comparable {
    public mutating func update(_ values: [Key: Value]) {
        merge(values) { _, new in new }
    }

    public func updating(_ values: [Key: Value]) -> Self {
        merging(values) { _, new in new }
    }

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
