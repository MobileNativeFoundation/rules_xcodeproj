import GeneratorCommon
import XcodeProj

extension Generator {
    /// Sets the dependencies for `PBXNativeTarget`s as defined in the matching
    /// `Target`.
    ///
    /// This is separate from `addTargets()` to ensure that all
    /// `PBXNativeTarget`s have been created first.
    static func setTargetDependencies(
        buildMode: BuildMode,
        disambiguatedTargets: DisambiguatedTargets,
        pbxTargets: [ConsolidatedTarget.Key: LabeledPBXNativeTarget],
        bazelDependenciesTarget: PBXAggregateTarget?
    ) throws {
        for (key, disambiguatedTarget) in disambiguatedTargets.targets {
            guard let labeledPBXTarget = pbxTargets[key] else {
                throw PreconditionError(message: """
Target \(key) not found in `pbxTargets`
""")
            }
            let pbxTarget = labeledPBXTarget.pbxTarget

            if let bazelDependenciesTarget = bazelDependenciesTarget {
                _ = try pbxTarget
                    .addDependency(target: bazelDependenciesTarget)
            }

            try disambiguatedTarget.target
                .dependencies(key: key, keys: disambiguatedTargets.keys)
                // Find the `PBXNativeTarget`s for the dependencies
                .compactMap { dependencyKey -> PBXNativeTarget? in
                    guard
                        let labeledDependency = pbxTargets[dependencyKey]
                    else {
                        throw PreconditionError(message: """
Target \(key)'s dependency on \(dependencyKey) not found in `pbxTargets`
""")
                    }
                    let dependency = labeledDependency.pbxTarget

                    return dependency
                }
                // Sort them by name
                .sorted { lhs, rhs in
                    return lhs.name.localizedStandardCompare(
                        rhs.name
                    ) == .orderedAscending
                }
                // Add the dependencies to the `PBXNativeTarget`
                .forEach { _ = try pbxTarget.addDependency(target: $0) }
        }
    }
}
