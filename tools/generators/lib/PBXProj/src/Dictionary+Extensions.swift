import GeneratorCommon

extension Dictionary {
    public mutating func update(_ values: [Key: Value]) {
        merge(values) { _, new in new }
    }

    public func updating(_ values: [Key: Value]) -> Self {
        merging(values) { _, new in new }
    }
}

extension Dictionary where Key: Comparable {
    public func value(
        for key: Key,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Value {
        guard let value = self[key] else {
            throw PreconditionError(
                message: """
\(context) "\(key)" not found in:
\(keys.sorted())
""",
                file: file,
                line: line
            )
        }
        return value
    }
}
