import PBXProj

extension Generator {
    struct CalculateContainerItemProxy {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `PBXContainerItemProxy` element for a target
        /// dependency.
        ///
        /// - Parameters:
        ///   - identifier: The identifier for the dependency target's
        ///     `PBXNativeTarget` element.
        func callAsFunction(
            identifier: Identifiers.Targets.Identifier
        ) -> String {
            return callable(
                /*identifier:*/ identifier
            )
        }
    }
}

// MARK: - CalculateContainerItemProxy.Callable

extension Generator.CalculateContainerItemProxy {
    typealias Callable = (
        _ identifier: Identifiers.Targets.Identifier
    ) -> String

    static func defaultCallable(
        identifier: Identifiers.Targets.Identifier
    ) -> String {
        // The tabs for indenting are intentional
        return #"""
{
			isa = PBXContainerItemProxy;
			containerPortal = \#(Identifiers.Project.id);
			proxyType = 1;
			remoteGlobalIDString = \#(identifier.withoutComment);
			remoteInfo = \#(identifier.name);
		}
"""#
    }
}
