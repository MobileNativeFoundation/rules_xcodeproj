import PBXProj

extension Generator {
    struct CreateTargetAttributesElements {
        private let calculateSingleTargetAttributes:
            CreateTargetAttributesElement

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            calculateSingleTargetAttributes: CreateTargetAttributesElement,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.calculateSingleTargetAttributes = calculateSingleTargetAttributes

            self.callable = callable
        }

        /// Calculates all the `PBXProject.targets` elements.
        func callAsFunction(
            identifiedTargets: [IdentifiedTarget],
            testHosts: [TargetID: TargetID],
            identifiers: [TargetID: Identifiers.Targets.Identifier],
            createdOnToolsVersion: String
        ) throws -> [Element] {
            return try callable(
                /*identifiedTargets:*/ identifiedTargets,
                /*testHosts:*/ testHosts,
                /*identifiers:*/ identifiers,
                /*createdOnToolsVersion:*/ createdOnToolsVersion,
                /*calculateSingleTargetAttributes:*/
                    calculateSingleTargetAttributes
            )
        }
    }
}

// MARK: - CalculateTargetAttributes.Callable

extension Generator.CreateTargetAttributesElements {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget],
        _ testHosts: [TargetID: TargetID],
        _ identifiers: [TargetID: Identifiers.Targets.Identifier],
        _ createdOnToolsVersion: String,
        _ calculateSingleTargetAttributes:
            Generator.CreateTargetAttributesElement
    ) throws -> [Element]

    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget],
        testHosts: [TargetID: TargetID],
        identifiers: [TargetID: Identifiers.Targets.Identifier],
        createdOnToolsVersion: String,
        calculateSingleTargetAttributes:
            Generator.CreateTargetAttributesElement
    ) throws -> [Element] {
        var targetAttributes: [Element] = [
            .init(
                identifier: Identifiers.BazelDependencies.id,
                content: calculateSingleTargetAttributes(
                    createdOnToolsVersion: createdOnToolsVersion,
                    testHostIdentifier: nil
                )
            ),
        ]

        for target in identifiedTargets {
            let anId = target.key.sortedIds.first!
            
            targetAttributes.append(
                Element(
                    identifier: target.identifier.full,
                    content: calculateSingleTargetAttributes(
                        createdOnToolsVersion: createdOnToolsVersion,
                        testHostIdentifier: try testHosts[anId].flatMap { id in
                            return try identifiers
                                .value(for: id, context: "Test host")
                                .full
                        }
                    )
                )
            )
        }

        return targetAttributes
    }
}
