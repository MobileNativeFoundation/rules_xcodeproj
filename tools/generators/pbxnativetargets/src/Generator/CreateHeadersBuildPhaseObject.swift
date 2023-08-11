import PBXProj

extension Generator {
    struct CreateHeadersBuildPhaseObject {
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

// MARK: - CreateHeadersBuildPhaseObject.Callable

extension Generator.CreateHeadersBuildPhaseObject {
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
			isa = PBXHeadersBuildPhase;
			buildActionMask = 2147483647;
			files = (
\#(buildFileIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			runOnlyForDeploymentPostprocessing = 0;
		}
"""#

        return Object(
            identifier: Identifiers.Targets.buildPhase(
                .headers,
                subIdentifier: subIdentifier
            ),
            content: content
        )
    }
}
