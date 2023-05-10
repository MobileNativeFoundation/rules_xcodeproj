import PBXProj

extension Generator {
    /// Calculates the `PBXProject` prefix `PBXProj` partial.
    static func calculate(
        compatibilityVersion: String,
        developmentRegion: String,
        organizationName: String?,
        projectDir: String,
        workspace: String
    ) -> String {
        let organizationNameAttribute: String
        if let organizationName = organizationName {
            organizationNameAttribute = #"""
				ORGANIZATIONNAME = \#(organizationName.pbxProjEscaped);

"""#
        } else {
            organizationNameAttribute = ""
        }

        // This is a `PBXProj` partial for _part of_ a `PBXProject` element.
        // Different generators will generate the remaining ports of the
        // `PBXProject` element. Because of this, it's intentional that the
        // element isn't terminated, and `attributes` is left open.
        //
        // The tabs for indenting are intentional. The trailing newlines are
        // intentional, as `cat` needs them to concatenate the partials
        // correctly.
        return #"""
		\#(Identifiers.Project.id) = {
			isa = PBXProject;
			buildConfigurationList = \#(Identifiers.Project.buildConfigurationList);
			compatibilityVersion = \#(compatibilityVersion.pbxProjEscaped);
			developmentRegion = \#(developmentRegion.pbxProjEscaped);
			hasScannedForEncodings = 0;
			mainGroup = \#(Identifiers.FilesAndGroups.mainGroup(workspace));
			productRefGroup = \#(Identifiers.FilesAndGroups.productsGroup);
			projectDirPath = \#(projectDir.pbxProjEscaped);
			projectRoot = "";
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 9999;
				LastUpgradeCheck = 9999;
\#(organizationNameAttribute)
"""#
    }
}
