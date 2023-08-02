import PBXProj

extension Generator {
    struct CreateContainerItemProxyObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Calculates the `PBXContainerItemProxy` object for a target
        /// dependency.
        ///
        /// - Parameters:
        ///   - subIdentifier: The sub-identifier for the target.
        ///   - dependencyIdentifier: The identifier for the dependency target's
        ///     `PBXNativeTarget` object.
        func callAsFunction(
            from subIdentifier: Identifiers.Targets.SubIdentifier,
            to dependencyIdentifier: Identifiers.Targets.Identifier
        ) -> Object {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*dependencyIdentifier:*/ dependencyIdentifier
            )
        }
    }
}

// MARK: - CalculateContainerItemProxy.Callable

extension Generator.CreateContainerItemProxyObject {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ dependencyIdentifier: Identifiers.Targets.Identifier
    ) -> Object

    static func defaultCallable(
        from subIdentifier: Identifiers.Targets.SubIdentifier,
        to dependencyIdentifier: Identifiers.Targets.Identifier
    ) -> Object {
        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXContainerItemProxy;
			containerPortal = \#(Identifiers.Project.id);
			proxyType = 1;
			remoteGlobalIDString = \#(dependencyIdentifier.withoutComment);
			remoteInfo = \#(dependencyIdentifier.pbxProjEscapedName);
		}
"""#

        return Object(
            identifier: Identifiers.Targets.containerItemProxy(
                from: subIdentifier,
                to: dependencyIdentifier.subIdentifier
            ),
            content: content
        )
    }
}
