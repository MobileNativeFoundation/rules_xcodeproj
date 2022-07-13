extension Dictionary where Key == TargetID, Value == Target {
    /// Find the first `TargetID` that satisfies the predicate starting with the specified
    /// `TargetID` values. This function will traverse the dependency tree in a breadth-first
    /// search.
    func firstTargetID<StartTargets: Sequence>(
        under startTargetIDs: StartTargets,
        where predicate: (Self.Value) throws -> Bool
    ) rethrows -> Self.Key? where StartTargets.Element == Self.Key {
        // Collect the targets for the specified targetID values
        let targetIDPairs: [(TargetID, Target)] = startTargetIDs.compactMap {
            if let target = self[$0] { return ($0, target) }
            return nil
        }

        // Check if any of the start targets satisfy the predicate.
        // If not, add their dependencies to the set of targetIDs to check next.
        var newStartIDs = Set<TargetID>()
        for (targetID, target) in targetIDPairs {
            if try predicate(target) { return targetID }
            newStartIDs.formUnion(target.dependencies)
        }

        // If there are no more targetIDs to check, then we are done
        // Otherwise, keep searching
        if newStartIDs.isEmpty { return nil }
        return try firstTargetID(under: newStartIDs, where: predicate)
    }
}
