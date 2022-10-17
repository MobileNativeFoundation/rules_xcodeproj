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
                .compactMap { dependencyKey -> PBXNativeTarget? in
                    guard
                        let dependency = pbxTargets.nativeTarget(dependencyKey)
                    else {
                        throw PreconditionError(message: """
Target \(key)'s dependency on \(dependencyKey) not found in `pbxTargets`
""")
                    }

                    guard disambiguatedTarget.target.shouldIncludeDependency(
                        dependency,
                        buildMode: buildMode
                    ) else {
                        return nil
                    }

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

extension ConsolidatedTarget {
    func shouldIncludeDependency(
        _ dependency: PBXNativeTarget,
        buildMode: BuildMode
    ) -> Bool {
        guard buildMode == .bazel else {
            return true
        }

        // Test hosts need to be copied
        return product.type.isTestBundle && dependency.isLaunchable
    }
}
