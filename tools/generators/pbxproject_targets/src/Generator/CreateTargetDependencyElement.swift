import PBXProj

extension Generator {
    struct CreateTargetDependencyElement {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `PBXTargetDependency` element for a target
        /// dependency.
        ///
        /// - Parameters:
        ///   - subIdentifier: The sub-identifier for the target.
        ///   - dependencyIdentifier: The identifier for the dependency target's
        ///     `PBXNativeTarget` element.
        ///   - containerItemProxyIdentifier: The identifier for the associated
        ///     `PBXContainerItemProxy` element.
        func callAsFunction(
            from subIdentifier: Identifiers.Targets.SubIdentifier,
            to dependencyIdentifier: Identifiers.Targets.Identifier,
            containerItemProxyIdentifier: String
        ) -> Element {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*dependencyIdentifier:*/ dependencyIdentifier,
                /*containerItemProxyIdentifier:*/ containerItemProxyIdentifier
            )
        }
    }
}

// MARK: - CalculateTargetDependency.Callable

extension Generator.CreateTargetDependencyElement {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ dependencyIdentifier: Identifiers.Targets.Identifier,
        _ containerItemProxyIdentifier: String
    ) -> Element

    static func defaultCallable(
        from subIdentifier: Identifiers.Targets.SubIdentifier,
        to dependencyIdentifier: Identifiers.Targets.Identifier,
        containerItemProxyIdentifier: String
    ) -> Element {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXTargetDependency;
			name = \#(dependencyIdentifier.pbxProjEscapedName);
			target = \#(dependencyIdentifier.full);
			targetProxy = \#(containerItemProxyIdentifier);
		}
"""#
        
        return Element(
            identifier: Identifiers.Targets.dependency(
                from: subIdentifier,
                to: dependencyIdentifier.subIdentifier
            ),
            content: content
        )
    }
}
