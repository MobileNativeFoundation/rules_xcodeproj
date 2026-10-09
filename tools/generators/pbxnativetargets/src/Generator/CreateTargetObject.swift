import PBXProj

extension Generator {
    struct CreateTargetObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates the `PBXNativeTarget` object for a target.
        func callAsFunction(
            identifier: Identifiers.Targets.Identifier,
            productType: PBXProductType,
            productName: String,
            productSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
            setsProductReference: Bool,
            dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier],
            buildConfigurationListIdentifier: String,
            buildPhaseIdentifiers: [String],
            synchronizedFolders: [BazelPath] = []
        ) -> Object {
            return callable(
                /*identifier:*/ identifier,
                /*productType:*/ productType,
                /*productName:*/ productName,
                /*productSubIdentifier:*/ productSubIdentifier,
                /*setsProductReference:*/ setsProductReference,
                /*dependencySubIdentifiers:*/ dependencySubIdentifiers,
                /*buildConfigurationListIdentifier:*/
                    buildConfigurationListIdentifier,
                /*buildPhaseIdentifiers:*/ buildPhaseIdentifiers,
                /*synchronizedFolders:*/ synchronizedFolders
            )
        }
    }
}

// MARK: - CreateTargetObject.Callable

extension Generator.CreateTargetObject {
    typealias Callable = (
        _ identifier: Identifiers.Targets.Identifier,
        _ productType: PBXProductType,
        _ productName: String,
        _ productSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
        _ setsProductReference: Bool,
        _ dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier],
        _ buildConfigurationListIdentifier: String,
        _ buildPhaseIdentifiers: [String],
        _ synchronizedFolders: [BazelPath]
    ) -> Object

    static func defaultCallable(
        identifier: Identifiers.Targets.Identifier,
        productType: PBXProductType,
        productName: String,
        productSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
        setsProductReference: Bool,
        dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier],
        buildConfigurationListIdentifier: String,
        buildPhaseIdentifiers: [String],
        synchronizedFolders: [BazelPath]
    ) -> Object {
        let productReference: String
        if setsProductReference {
            productReference = #"""
			productReference = \#(
    Identifiers.BuildFiles.id(subIdentifier: productSubIdentifier)
);

"""#
        } else {
            productReference = ""
        }

        // Folders whose contents Xcode adds to the target, created as
        // `PBXFileSystemSynchronizedRootGroup`s by the files_and_groups
        // generator with the same identifiers
        let fileSystemSynchronizedGroups: String
        if synchronizedFolders.isEmpty {
            fileSystemSynchronizedGroups = ""
        } else {
            fileSystemSynchronizedGroups = #"""
			fileSystemSynchronizedGroups = (
\#(
    synchronizedFolders
        .map { folder in
            let name = folder.path.split(separator: "/").last
                .map(String.init) ?? folder.path
            return """
\t\t\t\t\(
    Identifiers.FilesAndGroups.synchronizedRootGroup(folder.path, name: name)
),

"""
        }
        .joined()
)\#
			);

"""#
        }

        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXNativeTarget;
			buildConfigurationList = \#(buildConfigurationListIdentifier);
			buildPhases = (
\#(buildPhaseIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
			buildRules = (
			);
			dependencies = (
\#(
    dependencySubIdentifiers
        .map { depSubIdentifier in
            return """
\t\t\t\t\(
    Identifiers.Targets.dependency(
        from: identifier.subIdentifier,
        to: depSubIdentifier
    )
),

"""
        }
        .joined()
)\#
			);
\#(fileSystemSynchronizedGroups)\#
			name = \#(identifier.pbxProjEscapedName);
			productName = \#(productName.pbxProjEscaped);
\#(productReference)\#
			productType = "\#(productType.identifier)";
		}
"""#

        return Object(identifier: identifier.full, content: content)
    }
}
