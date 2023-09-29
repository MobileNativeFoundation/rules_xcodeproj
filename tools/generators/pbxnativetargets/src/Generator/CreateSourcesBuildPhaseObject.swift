import PBXProj

extension Generator {
    struct CreateSourcesBuildPhaseObject {
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
            buildFileIdentifiers: [String]
        ) -> Object {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*buildFileIdentifiers:*/ buildFileIdentifiers
            )
        }
    }
}

// MARK: - CreateSourcesBuildPhaseObject.Callable

extension Generator.CreateSourcesBuildPhaseObject {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ buildFileIdentifiers: [String]
    ) -> Object

    static func defaultCallable(
        subIdentifier: Identifiers.Targets.SubIdentifier,
        buildFileIdentifiers: [String]
    ) -> Object {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
\#(buildFileIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			runOnlyForDeploymentPostprocessing = 0;
		}
"""#

        return Object(
            identifier: Identifiers.Targets.buildPhase(
                .sources,
                subIdentifier: subIdentifier
            ),
            content: content
        )
    }
}
