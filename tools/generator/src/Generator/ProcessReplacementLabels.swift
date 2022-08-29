extension Generator {
    /// Replaces the labels and names of targets with new values.
    ///
    /// This is used to fix the labels and names of targets that have "internal"
    /// names, such as `*_{ui,unit}_test` rules naming the bundle rules with
    /// a `.__internal__.__test_bundle` suffix.
    ///
    /// - Parameters:
    ///   - targets: The universe of targets. These will be edited in place.
    ///   - targetMerges: A dictionary mapping target ids of targets
    ///     that should have their labels and names replaced to their new
    ///     labels.
    static func processReplacementLabels(
        targets: inout [TargetID: Target],
        replacementLabels: [TargetID: BazelLabel]
    ) throws {
        for (id, label) in replacementLabels {
            guard var target = targets[id] else {
                throw PreconditionError(message: """
Target with id "\(id)" from `replacement_labels` not found in `targets`.
""")
            }

            target.label = label
            target.name = label.name
            targets[id] = target
        }
    }
}
