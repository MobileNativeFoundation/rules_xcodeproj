// MARK: `collectPlatformsByKey`

extension Dictionary where Key == TargetID, Value == ConsolidatedTarget.Key {
    func collectPlatformsByKey(
        targets: [TargetID: Target]
    ) throws -> [ConsolidatedTarget.Key: Set<Platform>] {
        var result = [ConsolidatedTarget.Key: Set<Platform>]()
        for (targetID, key) in self {
            let target = try targets.value(for: targetID)
            result[key, default: []].insert(target.platform)
        }
        return result
    }
}
