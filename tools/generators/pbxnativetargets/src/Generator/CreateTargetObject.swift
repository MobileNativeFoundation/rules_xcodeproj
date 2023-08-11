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
            dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier],
            buildConfigurationListIdentifier: String,
            buildPhaseIdentifiers: [String]
        ) -> Object {
            return callable(
                /*identifier:*/ identifier,
                /*productType:*/ productType,
                /*productName:*/ productName,
                /*productSubIdentifier:*/ productSubIdentifier,
                /*dependencySubIdentifiers:*/ dependencySubIdentifiers,
                /*buildConfigurationListIdentifier:*/
                    buildConfigurationListIdentifier,
                /*buildPhaseIdentifiers:*/ buildPhaseIdentifiers
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
        _ dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier],
        _ buildConfigurationListIdentifier: String,
        _ buildPhaseIdentifiers: [String]
    ) -> Object

    static func defaultCallable(
        identifier: Identifiers.Targets.Identifier,
        productType: PBXProductType,
        productName: String,
        productSubIdentifier: Identifiers.BuildFiles.SubIdentifier,
        dependencySubIdentifiers: [Identifiers.Targets.SubIdentifier],
        buildConfigurationListIdentifier: String,
        buildPhaseIdentifiers: [String]
    ) -> Object {
        let productReference: String
        if productType.setsProductReference {
            productReference = #"""
			productReference = \#(
    Identifiers.BuildFiles.id(subIdentifier: productSubIdentifier)
);

"""#
        } else {
            productReference = ""
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
			name = \#(identifier.pbxProjEscapedName);
			productName = \#(productName.pbxProjEscaped);
\#(productReference)\#
			productType = "\#(productType.identifier)";
		}
"""#

        return Object(identifier: identifier.full, content: content)
    }
}
