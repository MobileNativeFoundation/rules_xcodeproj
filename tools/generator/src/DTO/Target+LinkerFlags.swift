import PathKit

extension Target {
    var hasLinkerFlags: Bool {
        return !linkerInputs.linkopts.isEmpty
            || !linkerInputs.staticLibraries.isEmpty
            || !inputs.exportedSymbolsLists.isEmpty
            || !linkerInputs.forceLoad.isEmpty
            || !linkerInputs.staticFrameworks.isEmpty
            || !linkerInputs.dynamicFrameworks.isEmpty
    }

    func allLinkerFlags(filePathResolver: FilePathResolver) throws -> [String] {
        var flags = try processLinkopts(
            linkerInputs.linkopts,
            swiftTriple: platform.swiftTriple,
            filePathResolver: filePathResolver
        )

        func handleFilePath(
            _ filePath: FilePath,
            useFilename: Bool
        ) throws -> String {
            let path = try filePathResolver.resolve(filePath)

            if useFilename {
                return path.lastComponentWithoutExtension
            } else {
                return path.string.quoted
            }
        }

        func handleFilePath(_ filePath: FilePath) throws -> String {
            return try handleFilePath(filePath, useFilename: false)
        }

        flags.append(
            contentsOf: try linkerInputs.staticLibraries.map(handleFilePath)
        )

        flags.append(contentsOf: try linkerInputs.forceLoad
            .flatMap { filePath in
                return [
                    "-force_load",
                    try handleFilePath(filePath),
                ]
            }
        )

        flags.append(
            contentsOf: try inputs.exportedSymbolsLists.flatMap { filePath in
                return [
                    "-exported_symbols_list",
                    try filePathResolver.resolve(filePath).string.quoted,
                ]
            }
        )

        // Frameworks being last here matches what the behavior should/will be:
        // https://github.com/bazelbuild/bazel/pull/16342
        flags.append(contentsOf: try linkerInputs.staticFrameworks
            .flatMap { filePath in
                return [
                    "-framework",
                    try handleFilePath(filePath, useFilename: true),
                ]
            }
        )

        flags.append(contentsOf: try linkerInputs.dynamicFrameworks
            .flatMap { filePath in
                return [
                    "-framework",
                    try handleFilePath(filePath, useFilename: true),
                ]
            }
        )

        return flags
    }
}

private func processLinkopts(
    _ linkopts: [String],
    swiftTriple: String,
    filePathResolver: FilePathResolver
) throws -> [String] {
    return try linkopts
        .map { linkopt in
            return try processLinkopt(
                linkopt,
                swiftTriple: swiftTriple,
                filePathResolver: filePathResolver
            )
        }
}

private func processLinkopt(
    _ linkopt: String,
    swiftTriple: String,
    filePathResolver: FilePathResolver
) throws -> String {
    return try linkopt
        .split(separator: ",")
        .map(String.init)
        .map { opt in
            return try processLinkoptComponent(
                opt,
                swiftTriple: swiftTriple,
                filePathResolver: filePathResolver
            )
        }
        .joined(separator: ",")
}

private func processLinkoptComponent(
    _ opt: String,
    swiftTriple: String,
    filePathResolver: FilePathResolver
) throws -> String {
    let extracted = extractOptValue(opt)
    var value = extracted.value

    let filePath: FilePath?
    if value.hasPrefix("bazel-out/") {
        filePath = .generated(Path(String(
            value[value.index(value.startIndex, offsetBy: 10)...]
        )))
    } else if value.hasPrefix("external/") {
        filePath = .external(Path(String(
            value[value.index(value.startIndex, offsetBy: 9)...]
        )))
    } else {
        filePath = nil
    }

    if var filePath = filePath {
        let xcodeGenerated = filePathResolver.xcodeGeneratedFiles.keys
            .contains(filePath)

        if xcodeGenerated {
            if let `extension` = filePath.path.extension,
               `extension` == "swiftmodule"
            {
                // swiftlint:disable:next shorthand_operator
                filePath = filePath + "\(swiftTriple).swiftmodule"
            }
        }

        value = try filePathResolver
            .resolve(filePath, useBazelOut: !xcodeGenerated)
            .string.quoted
    }

    return "\(extracted.prefix)\(value)"
}

private func extractOptValue(
    _ opt: String
) -> (prefix: String, value: String) {
    let components = opt.split(separator: "=", maxSplits: 1)
    guard components.count > 1 else {
        return ("", opt)
    }
    return ("\(components[0])=", String(components[1]))
}
