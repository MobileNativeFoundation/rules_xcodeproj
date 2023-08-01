import PBXProj

extension Generator {
    struct CreateDependencyObjects {
        private let createContainerItemProxyObject: CreateContainerItemProxyObject
        private let createTargetDependencyObject: CreateTargetDependencyObject

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createContainerItemProxyObject: CreateContainerItemProxyObject,
            createTargetDependencyObject: CreateTargetDependencyObject,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createContainerItemProxyObject =
                createContainerItemProxyObject
            self.createTargetDependencyObject = createTargetDependencyObject

            self.callable = callable
        }

        /// Calculates all the `PBXTargetDependency` and `PBXContainerItemProxy`
        /// objects.
        func callAsFunction(
            identifiedTargets: [IdentifiedTarget],
            identifiers: [TargetID: Identifiers.Targets.Identifier]
        ) throws -> [Object] {
            return try callable(
                /*identifiedTargets:*/ identifiedTargets,
                /*identifiers:*/ identifiers,
                /*createContainerItemProxyObject:*/
                    createContainerItemProxyObject,
                /*createTargetDependencyObject:*/ createTargetDependencyObject
            )
        }
    }
}

// MARK: - CalculateTargetDependencies.Callable

extension Generator.CreateDependencyObjects {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget],
        _ identifiers: [TargetID: Identifiers.Targets.Identifier],
        _ createContainerItemProxyObject:
            Generator.CreateContainerItemProxyObject,
        _ createTargetDependencyObject: Generator.CreateTargetDependencyObject
    ) throws -> [Object]

    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget],
        identifiers: [TargetID: Identifiers.Targets.Identifier],
        createContainerItemProxyObject:
            Generator.CreateContainerItemProxyObject,
        createTargetDependencyObject: Generator.CreateTargetDependencyObject
    ) throws -> [Object] {
        var targetDependencies: [Object] = []
        func addElements(
            from identifier: Identifiers.Targets.Identifier,
            to dependencyIdentifier: Identifiers.Targets.Identifier
        ) {
            let containerItemProxy = createContainerItemProxyObject(
                from: identifier.subIdentifier,
                to: dependencyIdentifier
            )
            targetDependencies.append(containerItemProxy)

            targetDependencies.append(
                createTargetDependencyObject(
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
