import PBXProj

extension Generator {
    struct CreateDependencyElements {
        private let createContainerItemProxyElement: CreateContainerItemProxyElement
        private let createTargetDependencyElement: CreateTargetDependencyElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createContainerItemProxyElement: CreateContainerItemProxyElement,
            createTargetDependencyElement: CreateTargetDependencyElement,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createContainerItemProxyElement =
                createContainerItemProxyElement
            self.createTargetDependencyElement = createTargetDependencyElement

            self.callable = callable
        }

        /// Calculates all the `PBXTargetDependency` and `PBXContainerItemProxy`
        /// elements.
        func callAsFunction(
            identifiedTargets: [IdentifiedTarget],
            identifiers: [TargetID: Identifiers.Targets.Identifier]
        ) throws -> [Element] {
            return try callable(
                /*identifiedTargets:*/ identifiedTargets,
                /*identifiers:*/ identifiers,
                /*createContainerItemProxyElement:*/
                    createContainerItemProxyElement,
                /*createTargetDependencyElement:*/ createTargetDependencyElement
            )
        }
    }
}

// MARK: - CalculateTargetDependencies.Callable

extension Generator.CreateDependencyElements {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget],
        _ identifiers: [TargetID: Identifiers.Targets.Identifier],
        _ createContainerItemProxyElement:
            Generator.CreateContainerItemProxyElement,
        _ createTargetDependencyElement: Generator.CreateTargetDependencyElement
    ) throws -> [Element]

    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget],
        identifiers: [TargetID: Identifiers.Targets.Identifier],
        createContainerItemProxyElement:
            Generator.CreateContainerItemProxyElement,
        createTargetDependencyElement: Generator.CreateTargetDependencyElement
    ) throws -> [Element] {
        var targetDependencies: [Element] = []
        func addElements(
            from identifier: Identifiers.Targets.Identifier,
            to dependencyIdentifier: Identifiers.Targets.Identifier
        ) {
            let containerItemProxy = createContainerItemProxyElement(
                from: identifier.subIdentifier,
                to: dependencyIdentifier
            )
            targetDependencies.append(containerItemProxy)

            targetDependencies.append(
                createTargetDependencyElement(
                    from: identifier.subIdentifier,
                    to: dependencyIdentifier,
                    containerItemProxyIdentifier:
                        containerItemProxy.identifier
                )
            )
        }

        for target in identifiedTargets {
            let identifier = target.identifier

            addElements(from: identifier, to: .bazelDependencies)

            for dependency in target.dependencies {
                let dependencyIdentifier = try identifiers.value(
                    for: dependency,
                    context: "Dependency"
                )

                addElements(from: identifier, to: dependencyIdentifier)
            }
        }

        return targetDependencies
    }
}
