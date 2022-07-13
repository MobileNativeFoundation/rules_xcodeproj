extension Collection where Index == TargetID, Element == Target {
    func findFirst<StartTargets: Sequence>(
        // TODO: Switch to BazelLabel
        label _: XcodeScheme.LabelValue,
        under _: StartTargets
    ) -> TargetID? where StartTargets.Element == TargetID {
        // TODO: IMPLEMENT ME!
        return nil
    }
}
