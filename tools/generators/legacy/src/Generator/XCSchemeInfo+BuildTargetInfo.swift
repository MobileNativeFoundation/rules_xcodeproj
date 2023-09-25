import OrderedCollections
import XcodeProj

extension XCSchemeInfo {
    struct BuildTargetInfo: Equatable, Hashable {
        let targetInfo: XCSchemeInfo.TargetInfo
        var buildFor: XcodeScheme.BuildFor

        init(
            targetInfo: XCSchemeInfo.TargetInfo,
            buildFor: XcodeScheme.BuildFor
        ) {
            self.targetInfo = targetInfo
            self.buildFor = buildFor
        }
    }
}

extension Sequence where Element == XCSchemeInfo.BuildTargetInfo {
    /// Return all of the `BuildAction.Entry` values.
    var buildActionEntries: [XCScheme.BuildAction.Entry] {
        get throws {
            // Create a (BuildableReference, BuildFor) for all buildable
            // references
            var buildRefAndBuildFors = flatMap { buildTargetInfo in
                return buildTargetInfo.targetInfo.selfAndHostBuildableReferences
                    .map { buildableReference in
                        return (
                            buildableReference: buildableReference,
                            productType: buildTargetInfo.targetInfo.productType,
                            buildFor: buildTargetInfo.buildFor
                        )
                    }
            }
                .sorted { lhs, rhs in
                    let lhsIsRunnable = lhs.productType.isRunnable
                    let rhsIsRunnable = rhs.productType.isRunnable
                    guard lhsIsRunnable == rhsIsRunnable else {
                        return lhsIsRunnable
                    }

                    if !lhsIsRunnable {
                        let lhsIsTest = lhs.productType.isTestBundle
                        let rhsIsTest = rhs.productType.isTestBundle
                        guard lhsIsTest == rhsIsTest else {
                            // Test come after other targets
                            return rhsIsTest
                        }
                    }

                    return lhs.buildableReference.blueprintName
                        .localizedStandardCompare(
                            rhs.buildableReference.blueprintName
                        ) == .orderedAscending
                }

            // Add additional targets after
            buildRefAndBuildFors.append(
                contentsOf: flatMap { buildTargetInfo in
                    return buildTargetInfo.targetInfo
                        .additionalBuildableReferences
                        .map { buildableReference in
                            return (
                                buildableReference: buildableReference,
                                productType:
                                    buildTargetInfo.targetInfo.productType,
                                buildFor: buildTargetInfo.buildFor
                            )
                        }
                }
                    // Sort by in stable order by blueprint name
                    .sortedLocalizedStandard(\.buildableReference.blueprintName)
            )

            // Collect the `buildFor`s by `BuildableReference`, and create the
            // `BuildAction.Entry` values
            return try OrderedDictionary(
                grouping: buildRefAndBuildFors,
                by: { $0.0 }
            ).map { buildableReference, buildRefAndBuildFors in
                return try XCScheme.BuildAction.Entry(
                    buildableReference: buildableReference,
                    buildFor: buildRefAndBuildFors
                        .map(\.buildFor).merged().xcSchemeValue
                )
            }
        }
    }
}
