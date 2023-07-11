import PBXProj

extension Generator {
    struct CalculateTargetDependency {
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
        ///   - identifier: The identifier for the dependency target's
        ///     `PBXNativeTarget` element.
        ///   - containerItemProxyIdentifier: The identifier for the associated
        ///     `PBXContainerItemProxy` element.
        func callAsFunction(
            identifier: Identifiers.Targets.Identifier,
            containerItemProxyIdentifier: String
        ) -> String {
            return callable(
                /*identifier:*/ identifier,
                /*containerItemProxyIdentifier:*/ containerItemProxyIdentifier
            )
        }
    }
}

// MARK: - CalculateTargetDependency.Callable

extension Generator.CalculateTargetDependency {
    typealias Callable = (
        _ identifier: Identifiers.Targets.Identifier,
        _ containerItemProxyIdentifier: String
    ) -> String

    static func defaultCallable(
        identifier: Identifiers.Targets.Identifier,
        containerItemProxyIdentifier: String
    ) -> String {
        // The tabs for indenting are intentional
        return #"""
{
			isa = PBXTargetDependency;
			name = \#(identifier.name);
			target = \#(identifier.full);
			targetProxy = \#(containerItemProxyIdentifier);
		}
"""#
    }
}
