extension Sequence {
    func anySatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        return try first(where: predicate) != nil
    }
}
