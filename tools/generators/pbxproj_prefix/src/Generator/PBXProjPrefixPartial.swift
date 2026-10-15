import PBXProj
import ToolCommon

extension Generator {
    /// Calculates `PBXProj` prefix partial.
    static func pbxProjPrefixPartial(
        bazelDependenciesPartial: String,
        pbxProjectPrefixPartial: String,
        minimumXcodeVersion: SemanticVersion,
        usesSynchronizedFolders: Bool = false
    ) -> String {
        // `PBXFileSystemSynchronizedRootGroup`s need object version 70, which
        // is what Xcode writes for such projects with the compatibility
        // version that we set. Other projects keep the version for
        // `minimumXcodeVersion`, so they don't change.
        let objectVersion = usesSynchronizedFolders ?
            max(minimumXcodeVersion.pbxProjObjectVersion, 70) :
            minimumXcodeVersion.pbxProjObjectVersion

        // This is a `PBXProj` partial for the start of the `PBXProj` element.
        //
        // The tabs for indenting are intentional. The trailing newlines are
        // intentional, as `cat` needs them to concatenate the partials
        // correctly.
        return #"""
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = \#(objectVersion);
	objects = {
\#(bazelDependenciesPartial)\#
\#(pbxProjectPrefixPartial)\#

"""#
    }
}

private extension SemanticVersion {
    var pbxProjObjectVersion: UInt {
        switch major {
            case 15...: return 60
            case 14: return 56
            default: return 55 // Xcode 13
        }
    }
}
