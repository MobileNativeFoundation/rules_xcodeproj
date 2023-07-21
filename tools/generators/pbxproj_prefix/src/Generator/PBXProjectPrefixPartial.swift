import PBXProj

extension Generator {
    /// Calculates the `PBXProject` prefix `PBXProj` partial.
    static func pbxProjectPrefixPartial(
        buildSettings: String,
        compatibilityVersion: String,
        defaultXcodeConfiguration: String,
        developmentRegion: String,
        organizationName: String?,
        projectDir: String,
        workspace: String,
        xcodeConfigurations: [String]
    ) -> String {
        // Organization name

        let organizationNameAttribute: String
        if let organizationName = organizationName {
            organizationNameAttribute = #"""
				ORGANIZATIONNAME = \#(organizationName.pbxProjEscaped);

"""#
        } else {
            organizationNameAttribute = ""
        }

        // Build configurations

        let buildConfigurations =  xcodeConfigurations
            .enumerated()
            .map { index, name in
                let id = Identifiers.Project
                    .buildConfiguration(name, index: UInt8(index))
                return (
                    id: id,
                    element: #"""
		\#(id) = {
			isa = XCBuildConfiguration;
			buildSettings = \#(buildSettings);
			name = \#(name.pbxProjEscaped);
		};
"""#
                )
            }

        // Final form

        // This is a `PBXProj` partial for `PBXProject` related objects and
        // _part of_ the `PBXProject` element. Different generators will
        // generate the remaining parts of the `PBXProject` element. Because of
        // this, it's intentional that the element isn't terminated, and
        // `attributes` is left open.
        //
        // The tabs for indenting are intentional. The trailing newlines are
        // intentional, as `cat` needs them to concatenate the partials
        // correctly.
        return #"""
\#(buildConfigurations.map(\.element).joined(separator: "\n"))
		\#(Identifiers.Project.buildConfigurationList) = {
			isa = XCConfigurationList;
			buildConfigurations = (
\#(
    buildConfigurations
        .map { id, _ in "\t\t\t\t\(id),"}.joined(separator: "\n")
)
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = \#(
                defaultXcodeConfiguration.pbxProjEscaped
            );
		};
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
