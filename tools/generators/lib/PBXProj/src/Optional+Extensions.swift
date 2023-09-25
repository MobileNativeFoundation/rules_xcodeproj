import ArgumentParser

// MARK: - ExpressibleByArgument

extension Optional: ExpressibleByArgument where Wrapped: ExpressibleByArgument {
    public init?(argument: String) {
        if argument.isEmpty {
            self = .none
        } else {
            self = Wrapped(argument: argument)
        }
    }
}
