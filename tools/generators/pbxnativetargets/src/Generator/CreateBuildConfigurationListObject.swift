import PBXProj

extension Generator {
    struct CreateBuildConfigurationListObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates the `XCConfigurationList` object for a target.
        func callAsFunction(
            name: String,
            subIdentifier: Identifiers.Targets.SubIdentifier,
            buildConfigurationIdentifiers: [String],
            defaultXcodeConfiguration: String
        ) -> Object {
            return callable(
                /*name:*/ name,
                /*subIdentifier:*/ subIdentifier,
                /*buildConfigurationIdentifiers:*/
                    buildConfigurationIdentifiers,
                /*defaultXcodeConfiguration:*/ defaultXcodeConfiguration
            )
        }
    }
}

// MARK: - CreateBuildConfigurationListObject.Callable

extension Generator.CreateBuildConfigurationListObject {
    typealias Callable = (
        _ name: String,
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ buildConfigurationIdentifiers: [String],
        _ defaultXcodeConfiguration: String
    ) -> Object

    static func defaultCallable(
        name: String,
        subIdentifier: Identifiers.Targets.SubIdentifier,
        buildConfigurationIdentifiers: [String],
        defaultXcodeConfiguration: String
    ) -> Object {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = XCConfigurationList;
			buildConfigurations = (
\#(buildConfigurationIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = \#(
                defaultXcodeConfiguration.pbxProjEscaped
            );
		}
"""#
        
        return Object(
            identifier: Identifiers.Targets.buildConfigurationList(
                subIdentifier: subIdentifier,
                name: name
            ),
            content: content
        )
    }
}
