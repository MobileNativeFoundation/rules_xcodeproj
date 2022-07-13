extension Collection where Index == TargetID, Element == Target {
    func firstTargetID<StartTargets: Sequence>(
        under startTargetIDs: StartTargets,
        where predicate: (TargetID, Target) throws -> Bool
    ) rethrows -> TargetID? where StartTargets.Element == TargetID {
        // Collect the targets for the specified targetID values
        let targetIDPairs = startTargetIDs.map { ($0, self[$0]) }

        // Check if any of the start targets satisfy the predicate.
        // If not, add their dependencies to the set of targetIDs to check next.
        var newStartIDs = Set<TargetID>()
        for (targetID, target) in targetIDPairs {
            if try predicate(targetID, target) {
                return targetID
            }
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
