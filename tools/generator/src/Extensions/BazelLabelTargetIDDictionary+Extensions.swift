extension Dictionary where Key == BazelLabel, Value == TargetID {
    func targetID(
        for label: BazelLabel,
        context: @autoclosure () -> String = ""
    ) throws -> TargetID {
        guard let targetID = self[label] else {
            let contextStr = context()
            let endOfMsg = contextStr.isEmpty ? "" : " while \(contextStr)"
            throw PreconditionError(message: """
Unable to find the `TargetID` for the BazelLabel "\(label)"\(endOfMsg).
""")
        }
        return targetID
    }
}
