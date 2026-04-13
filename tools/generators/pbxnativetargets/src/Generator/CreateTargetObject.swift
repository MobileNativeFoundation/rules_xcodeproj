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
            synchronizedFolderIdentifiers: [String]
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
                /*synchronizedFolderIdentifiers:*/
                    synchronizedFolderIdentifiers
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
        _ synchronizedFolderIdentifiers: [String]
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
        synchronizedFolderIdentifiers: [String]
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

        let content = #"""
{
			isa = PBXNativeTarget;
			buildConfigurationList = \#(buildConfigurationListIdentifier);
			buildPhases = (
\#(serializedEntries(buildPhaseIdentifiers))\#
			);
			buildRules = (
			);
			dependencies = (
\#(serializedDependencies(
    from: identifier.subIdentifier,
    dependencySubIdentifiers: dependencySubIdentifiers
))\#
			);
\#(serializedOptionalSynchronizedGroups(synchronizedFolderIdentifiers))\#
			name = \#(identifier.pbxProjEscapedName);
			productName = \#(productName.pbxProjEscaped);
\#(productReference)\#
			productType = "\#(productType.identifier)";
		}
"""#

        return Object(identifier: identifier.full, content: content)
    }
}

private func serializedEntries(_ values: [String]) -> String {
    return values.map { "\t\t\t\t\($0),\n" }.joined()
}

private func serializedDependencies(
    from subIdentifier: Identifiers.Targets.SubIdentifier,
    dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier]
) -> String {
    return dependencySubIdentifiers
        .map { dependencySubIdentifier in
            return """
\t\t\t\t\(
    Identifiers.Targets.dependency(
        from: subIdentifier,
        to: dependencySubIdentifier
    )
),

"""
        }
        .joined()
}

private func serializedOptionalSynchronizedGroups(
    _ synchronizedFolderIdentifiers: [String]
) -> String {
    guard !synchronizedFolderIdentifiers.isEmpty else {
        return ""
    }

    return """
			fileSystemSynchronizedGroups = (
\(serializedEntries(
        synchronizedFolderIdentifiers
    ))			);

"""
}
