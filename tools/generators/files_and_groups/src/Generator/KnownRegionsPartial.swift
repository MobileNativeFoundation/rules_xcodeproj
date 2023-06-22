import PBXProj

extension Generator {
    /// Calculates the `PBXProject.knownRegions` `PBXProj` partial.
    static func knownRegionsPartial(
        knownRegions: Set<String>,
        developmentRegion: String,
        useBaseInternationalization: Bool
    ) -> String {
        var knownRegions = knownRegions

        knownRegions.insert(developmentRegion)

        let sortedKnownRegions: [String]
        if useBaseInternationalization {
            // Xcode puts "Base" last after sorting
            knownRegions.remove("Base")
            sortedKnownRegions = knownRegions.sorted() + ["Base"]
        } else {
            sortedKnownRegions = knownRegions.sorted()
        }

        // The tabs for indenting are intentional. The trailing newlines are
        // intentional, as `cat` needs them to concatenate the partials
        // correctly.
        return #"""
			knownRegions = (
\#(
    sortedKnownRegions
        .map { "\t\t\t\t\($0.pbxProjEscaped)," }
        .joined(separator: "\n")
)
			);

"""#
    }
}
