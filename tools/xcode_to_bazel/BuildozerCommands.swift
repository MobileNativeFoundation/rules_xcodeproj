func buildozerCommandsForBazelPackages(
    _ packages: [Package],
    existingTargets: Set<Label>,
    existingBazelDeps: Set<String>
) -> [String] {
    var commands = packages.flatMap { package in
        var commands: [String] = []

        // Package

        var packageCommands = ["fix movePackageToTop"]

        for loadStatement in package.loadStatements {
            packageCommands.append(
                "new_load \(loadStatement.key) \(loadStatement.value.sorted().joined(separator: " "))"
            )
        }

        for target in package.targets {
            if !existingTargets.contains(target.label) {
                packageCommands.append("new \(target.kind) \(target.label.name)")
            }
        }

        packageCommands.append("//\(package.path):__pkg__")

        commands.append(packageCommands.joined(separator: "|"))

        // Targets

        for target in package.targets {
            var attrsCommands =
                target.singleAttrs.map { "set \($0.key) \($0.value)" }
            attrsCommands.append(
                contentsOf: target.listAttrs
                    .flatMap { attr, values in
                        return values.map { "add \(attr) \($0)" }
                    }
            )
            if !attrsCommands.isEmpty {
                attrsCommands.append(target.label.description)
                commands.append(attrsCommands.joined(separator: "|"))
            }
        }

        return commands
    }

    var newBazelDeps = Set(packages.flatMap { $0.targets.map { $0.kind.bazelDep } })
        .filter { !existingBazelDeps.contains($0.module) }

    // FIXME: Determine if we need rspm
    newBazelDeps.insert(.rulesSPM)

    if !newBazelDeps.isEmpty {
        // Add new `bazel_dep`s
        var newDepsCommands = newBazelDeps
            .sorted { $0.order < $1.order }
            .map { "new bazel_dep \($0.module) before __pkg__" }
        newDepsCommands.append("//MODULE.bazel:all")
        commands.append(newDepsCommands.joined(separator: "|"))

        // Set repo_name
        commands.append(
            contentsOf: newBazelDeps
                .filter { !$0.repoName.isEmpty }
                .map { #"set repo_name "\#($0.repoName)"|//MODULE.bazel:\#($0.module)"# }
        )

        // Set versions
        commands.append(contentsOf: newBazelDeps.map { #"set version "\#($0.version)"|//MODULE.bazel:\#($0.module)"# })
    }

    return commands
}
