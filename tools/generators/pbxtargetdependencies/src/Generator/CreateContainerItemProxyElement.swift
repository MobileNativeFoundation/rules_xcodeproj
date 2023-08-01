import PBXProj

extension Generator {
    struct CreateContainerItemProxyElement {
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
        ///   - subIdentifier: The sub-identifier for the target.
        ///   - dependencyIdentifier: The identifier for the dependency target's
        ///     `PBXNativeTarget` element.
        func callAsFunction(
            from subIdentifier: Identifiers.Targets.SubIdentifier,
            to dependencyIdentifier: Identifiers.Targets.Identifier
        ) -> Element {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*dependencyIdentifier:*/ dependencyIdentifier
            )
        }
    }
}

// MARK: - CalculateContainerItemProxy.Callable

extension Generator.CreateContainerItemProxyElement {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ dependencyIdentifier: Identifiers.Targets.Identifier
    ) -> Element

    static func defaultCallable(
        from subIdentifier: Identifiers.Targets.SubIdentifier,
        to dependencyIdentifier: Identifiers.Targets.Identifier
    ) -> Element {
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

        return Element(
            identifier: Identifiers.Targets.containerItemProxy(
                from: subIdentifier,
                to: dependencyIdentifier.subIdentifier
            ),
            content: content
        )
    }
}
