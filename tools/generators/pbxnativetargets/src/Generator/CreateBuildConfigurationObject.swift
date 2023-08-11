import PBXProj

extension Generator {
    struct CreateBuildConfigurationObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates a `XCBuildConfiguration` object for a target.
        func callAsFunction(
            name: String,
            index: UInt8,
            subIdentifier: Identifiers.Targets.SubIdentifier,
            buildSettings: String
        ) -> Object {
            return callable(
                /*name:*/ name,
                /*index:*/ index,
                /*subIdentifier:*/ subIdentifier,
                /*buildSettings:*/ buildSettings
            )
        }
    }
}

// MARK: - CreateBuildConfigurationObject.Callable

extension Generator.CreateBuildConfigurationObject {
    typealias Callable = (
        _ name: String,
        _ index: UInt8,
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ defaultXcodeConfiguration: String
    ) -> Object

    static func defaultCallable(
        name: String,
        index: UInt8,
        subIdentifier: Identifiers.Targets.SubIdentifier,
        buildSettings: String
    ) -> Object {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = XCBuildConfiguration;
			buildSettings = \#(buildSettings);
			name = \#(name.pbxProjEscaped);
		}
"""#
        
        return Object(
            identifier: Identifiers.Targets.buildConfiguration(
                name,
                index: index,
                subIdentifier: subIdentifier
            ),
            content: content
        )
    }
}
