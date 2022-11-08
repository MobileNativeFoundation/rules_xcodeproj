import PathKit

extension Target {
    var hasLinkerFlags: Bool {
        return !linkerInputs.linkopts.isEmpty
            || !linkerInputs.staticLibraries.isEmpty
            || !inputs.exportedSymbolsLists.isEmpty
            || !linkerInputs.forceLoad.isEmpty
    }

    func allLinkerFlags(filePathResolver: FilePathResolver) -> [String] {
        var flags = processLinkopts(
            linkerInputs.linkopts,
            swiftTriple: platform.swiftTriple,
            filePathResolver: filePathResolver
        )

        func handleFilePath(
            _ filePath: FilePath,
            useFilename: Bool
        ) -> String {
            let path = filePathResolver.resolve(filePath)

            if useFilename {
                return path.lastComponentWithoutExtension
            } else {
                return path.string.quoted
            }
        }

        func handleFilePath(_ filePath: FilePath) -> String {
            return handleFilePath(filePath, useFilename: false)
        }

        flags.append(
            contentsOf: linkerInputs.staticLibraries.map(handleFilePath)
        )

        flags.append(contentsOf: linkerInputs.forceLoad
            .flatMap { filePath in
                return [
                    "-force_load",
                    handleFilePath(filePath),
                ]
            }
        )

        flags.append(
            contentsOf: inputs.exportedSymbolsLists.flatMap { filePath in
                return [
                    "-exported_symbols_list",
                    filePathResolver.resolve(
                        filePath,
                        useBazelOut: true
                    ).string.quoted,
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
) -> [String] {
    return linkopts
        .map { linkopt in
            return processLinkopt(
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
) -> String {
    return linkopt
        .split(separator: ",")
        .map(String.init)
        .map { opt in
            return processLinkoptComponent(
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
) -> String {
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

    if let filePath = filePath {
        value = filePathResolver
            .resolve(
                filePath,
                xcodeGeneratedTransform: { filePath in
                    guard let `extension` = filePath.path.extension,
                       `extension` == "swiftmodule" else {
                        return filePath
                    }
                    // swiftlint:disable:next shorthand_operator
                    return filePath + "\(swiftTriple).swiftmodule"
                }
            )
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
