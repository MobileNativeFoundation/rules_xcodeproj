// extension Collection where Index == TargetID, Element == Target {
extension Dictionary where Key == TargetID, Value == Target {
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
        if newStartIDs.isEmpty {
            return nil
        }
        return try firstTargetID(under: newStartIDs, where: predicate)
    }

    // func firstTargetID<StartTargets: Sequence>(
    //     // TODO: Switch to BazelLabel
    //     label: XcodeScheme.LabelValue,
    //     under startTargetIDs: StartTargets
    // ) -> TargetID? where StartTargets.Element == TargetID {
    //     // Collect the targets for the specified targetID values
    //     let targetIDPairs = startTargetIDs.map { ($0, self[$0]) }

    //     // Check if any of the start targets are the desired label.
    //     // If not, add their dependencies to the set of targetIDs to check next.
    //     var newStartIDs = Set<TargetID>()
    //     for (targetID, target) in targetIDPairs {
    //         if target.label == label {
    //             return targetID
    //         }
    //         newStartIDs.formUnion(target.dependencies)
    //     }

    //     // If there are no more targetIDs to check, then we are done
    //     // Otherwise, keep searching
    //     if newStartIDs.isEmpty {
    //         return nil
    //     }
    //     return firstTargetID(label: label, under: newStartIDs)
    // }
}
