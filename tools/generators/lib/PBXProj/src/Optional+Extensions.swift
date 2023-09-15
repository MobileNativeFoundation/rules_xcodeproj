import ArgumentParser

// MARK: - ExpressibleByArgument

extension Optional: ExpressibleByArgument where Wrapped: ExpressibleByArgument {
    public init?(argument: String) {
        guard !argument.isEmpty else {
            return nil
        }
        self = Wrapped(argument: argument)
    }
}
