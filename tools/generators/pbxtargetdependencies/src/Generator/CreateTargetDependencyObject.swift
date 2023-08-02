import PBXProj

extension Generator {
    struct CreateTargetDependencyObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `PBXTargetDependency` object for a target
        /// dependency.
        ///
        /// - Parameters:
        ///   - subIdentifier: The sub-identifier for the target.
        ///   - dependencyIdentifier: The identifier for the dependency target's
        ///     `PBXNativeTarget` object.
        ///   - containerItemProxyIdentifier: The identifier for the associated
        ///     `PBXContainerItemProxy` object.
        func callAsFunction(
            from subIdentifier: Identifiers.Targets.SubIdentifier,
            to dependencyIdentifier: Identifiers.Targets.Identifier,
            containerItemProxyIdentifier: String
        ) -> Object {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*dependencyIdentifier:*/ dependencyIdentifier,
                /*containerItemProxyIdentifier:*/ containerItemProxyIdentifier
            )
        }
    }
}

// MARK: - CalculateTargetDependency.Callable

extension Generator.CreateTargetDependencyObject {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ dependencyIdentifier: Identifiers.Targets.Identifier,
        _ containerItemProxyIdentifier: String
    ) -> Object

    static func defaultCallable(
        from subIdentifier: Identifiers.Targets.SubIdentifier,
        to dependencyIdentifier: Identifiers.Targets.Identifier,
        containerItemProxyIdentifier: String
    ) -> Object {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXTargetDependency;
			name = \#(dependencyIdentifier.pbxProjEscapedName);
			target = \#(dependencyIdentifier.full);
			targetProxy = \#(containerItemProxyIdentifier);
		}
"""#

        return Object(
            identifier: Identifiers.Targets.dependency(
                from: subIdentifier,
                to: dependencyIdentifier.subIdentifier
            ),
            content: content
        )
    }
}
