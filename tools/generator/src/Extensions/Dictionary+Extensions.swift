extension Dictionary where Key == TargetID, Value == Target {
    /// Filter the dictionary to include the depdency tree for the specified target ID values that
    /// satisfy the provided predicate.
    func filterDependencyTree<StartTargets: Sequence>(
        startingWith startTargetIDs: StartTargets,
        _ isIncluded: (Self.Value) throws -> Bool
    ) rethrows -> [Key: Value] where StartTargets.Element == Self.Key {
        // Filter the dictionary to the start targetIDs
        let targetIDs = Set(startTargetIDs)
        let result = try filter { targetID, target in
            if !targetIDs.contains(targetID) { return false }
            return try isIncluded(target)
        }

        // Check for dependencies
        let depTargetIDs = Set(result.values.map(\.dependencies).flatMap { $0 })
        if depTargetIDs.isEmpty { return result }

        // Collect the dependencies for the start targets
        let deps = try filterDependencyTree(startingWith: depTargetIDs, isIncluded)

        // Merge the results
        return result.merging(deps) { current, _ in current }
    }

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
