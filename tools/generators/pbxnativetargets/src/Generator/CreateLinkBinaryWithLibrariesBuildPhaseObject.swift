import PBXProj

extension Generator {
    struct CreateLinkBinaryWithLibrariesBuildPhaseObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates the `PBXSourcesBuildPhase` object for a target.
        func callAsFunction(
            subIdentifier: Identifiers.Targets.SubIdentifier,
            librariesToLinkIdentifiers: [String]
        ) -> Object {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*buildFileIdentifiers:*/ librariesToLinkIdentifiers
            )
        }
    }
}

// MARK: - CreateSourcesBuildPhaseObject.Callable

extension Generator.CreateLinkBinaryWithLibrariesBuildPhaseObject {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ librariesToLinkIdentifiers: [String]
    ) -> Object

    static func defaultCallable(
        subIdentifier: Identifiers.Targets.SubIdentifier,
        librariesToLinkIdentifiers: [String]
    ) -> Object {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
\#(librariesToLinkIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			runOnlyForDeploymentPostprocessing = 0;
		}
"""#

        return Object(
            identifier: Identifiers.Targets.buildPhase(
                .linkBinaryWithLibraries,
                subIdentifier: subIdentifier
            ),
            content: content
        )
    }
}
