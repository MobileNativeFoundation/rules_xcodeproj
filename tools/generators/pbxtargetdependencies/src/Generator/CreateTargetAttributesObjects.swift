import PBXProj

extension Generator {
    struct CreateTargetAttributesObjects {
        private let createTargetAttributesContent: CreateTargetAttributesContent

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createTargetAttributesContent: CreateTargetAttributesContent,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createTargetAttributesContent = createTargetAttributesContent

            self.callable = callable
        }

        /// Calculates all the `PBXProject.targets` objects.
        func callAsFunction(
            identifiedTargets: [IdentifiedTarget],
            testHosts: [TargetID: TargetID],
            identifiers: [TargetID: Identifiers.Targets.Identifier],
            createdOnToolsVersion: String
        ) throws -> [Object] {
            return try callable(
                /*identifiedTargets:*/ identifiedTargets,
                /*testHosts:*/ testHosts,
                /*identifiers:*/ identifiers,
                /*createdOnToolsVersion:*/ createdOnToolsVersion,
                /*createTargetAttributesContent:*/ createTargetAttributesContent
            )
        }
    }
}

// MARK: - CalculateTargetAttributes.Callable

extension Generator.CreateTargetAttributesObjects {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget],
        _ testHosts: [TargetID: TargetID],
        _ identifiers: [TargetID: Identifiers.Targets.Identifier],
        _ createdOnToolsVersion: String,
        _ createTargetAttributesContent: Generator.CreateTargetAttributesContent
    ) throws -> [Object]

    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget],
        testHosts: [TargetID: TargetID],
        identifiers: [TargetID: Identifiers.Targets.Identifier],
        createdOnToolsVersion: String,
        createTargetAttributesContent: Generator.CreateTargetAttributesContent
    ) throws -> [Object] {
        var targetAttributes: [Object] = [
            .init(
                identifier: Identifiers.BazelDependencies.id,
                content: createTargetAttributesContent(
                    createdOnToolsVersion: createdOnToolsVersion,
                    testHostIdentifier: nil
                )
            ),
        ]

        for target in identifiedTargets {
            let anId = target.key.sortedIds.first!

            targetAttributes.append(
                Object(
                    identifier: target.identifier.full,
                    content: createTargetAttributesContent(
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
