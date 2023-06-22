import PBXProj

extension Generator {
    /// Calculates the files and groups `PBXProj` partial.
    static func filesAndGroupsPartial(
        elementsPartial: String
    ) -> String {
        // The tabs for indenting are intentional. The trailing newlines are
        // intentional, as `cat` needs them to concatenate the partials
        // correctly.
        return #"""
\#(elementsPartial)\#

"""#
    }
}
