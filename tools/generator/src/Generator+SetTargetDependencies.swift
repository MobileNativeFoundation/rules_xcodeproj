import XcodeProj

extension Generator {
    /// Sets the dependencies for `PBXNativeTarget`s as defined in the matching
    /// `Target`.
    ///
    /// This is separate from `addTargets()` to ensure that all
    /// `PBXNativeTarget`s have been created first.
    static func setTargetDependencies(
        disambiguatedTargets: [TargetID: DisambiguatedTarget],
        pbxTargets: [TargetID: PBXNativeTarget]
    ) throws {
        for (id, disambiguatedTarget) in disambiguatedTargets {
            guard let pbxTarget = pbxTargets[id] else {
                throw PreconditionError(message: """
Target "\(id)" not found in `pbxTargets`
""")
            }

            try disambiguatedTarget.target.dependencies
                // Find the `PBXNativeTarget`s for the dependencies
                .map { dependency -> PBXNativeTarget in
                    guard let nativeDependency = pbxTargets[dependency] else {
                        throw PreconditionError(message: """
Target "\(id)"'s dependency on "\(dependency)" not found in `pbxTargets`
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
