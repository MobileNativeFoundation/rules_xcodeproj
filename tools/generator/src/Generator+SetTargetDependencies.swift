import XcodeProj

extension Generator {
    /// Sets the dependencies for `PBXNativeTarget`s as defined in the matching
    /// `Target`.
    ///
    /// This is separate from `addTargets()` to ensure that all
    /// `PBXNativeTarget`s have been created first.
    static func setTargetDependencies(
        disambiguatedTargets: DisambiguatedTargets,
        pbxTargets: [ConsolidatedTarget.Key: PBXTarget]
    ) throws {
        for (key, disambiguatedTarget) in disambiguatedTargets.targets {
            guard let pbxTarget = pbxTargets.nativeTarget(key) else {
                throw PreconditionError(message: """
Target \(key) not found in `pbxTargets`
""")
            }

            try disambiguatedTarget.target
                .dependencies(key: key, keys: disambiguatedTargets.keys)
                // Find the `PBXNativeTarget`s for the dependencies
                .map { dependencyKey -> PBXNativeTarget in
                    guard
                        let nativeDependency = pbxTargets
                            .nativeTarget(dependencyKey)
                    else {
                        throw PreconditionError(message: """
Target \(key)'s dependency on \(dependencyKey) not found in `pbxTargets`
""")
                    }
                    return nativeDependency
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
