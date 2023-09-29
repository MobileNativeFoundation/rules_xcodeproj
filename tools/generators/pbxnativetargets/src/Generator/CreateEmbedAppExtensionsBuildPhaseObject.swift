import PBXProj

extension Generator {
    struct CreateEmbedAppExtensionsBuildPhaseObject {
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

// MARK: - CreateEmbedAppExtensionsBuildPhaseObject.Callable

extension Generator.CreateEmbedAppExtensionsBuildPhaseObject {
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
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 13;
			files = (
\#(buildFileIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			name = "Embed App Extensions";
			runOnlyForDeploymentPostprocessing = 0;
		}
"""#

        return Object(
            identifier: Identifiers.Targets.buildPhase(
                .embedAppExtensions,
                subIdentifier: subIdentifier
            ),
            content: content
        )
    }
}
