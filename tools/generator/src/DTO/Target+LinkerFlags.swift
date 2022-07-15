import PathKit

extension Target {
    var hasLinkerFlags: Bool {
        return !linkerInputs.linkopts.isEmpty
            || !linkerInputs.staticLibraries.isEmpty
            || !inputs.exportedSymbolsLists.isEmpty
            || !linkerInputs.forceLoad.isEmpty
    }

    func allLinkerFlags(
        xcodeGeneratedFiles: Set<FilePath>,
        filePathResolver: FilePathResolver
    ) throws -> [String] {
        var flags = try processLinkopts(
            linkerInputs.linkopts,
            xcodeGeneratedFiles: xcodeGeneratedFiles,
            filePathResolver: filePathResolver
        )

        if !linkerInputs.staticLibraries.isEmpty {
            let linkFileList = try filePathResolver
                .resolve(try linkFileListFilePath())
                .string
            flags.append(contentsOf: ["-filelist", linkFileList.quoted])
        }

        let exportedSymbolsLists = inputs.exportedSymbolsLists
        if !exportedSymbolsLists.isEmpty {
            flags.append(
                contentsOf: try exportedSymbolsLists.flatMap { filePath in
                    return [
                        "-exported_symbols_list",
                        try filePathResolver.resolve(filePath).string.quoted,
                    ]
                }
            )
        }

        let forceLoadLibraries = linkerInputs.forceLoad
        if !forceLoadLibraries.isEmpty {
            flags.append(
                contentsOf: try forceLoadLibraries.flatMap { filePath in
                    return [
                        "-force_load",
                        try filePathResolver.resolve(filePath).string.quoted,
                    ]
                }
            )
        }

        return flags
    }
}

private func processLinkopts(
    _ linkopts: [String],
    xcodeGeneratedFiles: Set<FilePath>,
    filePathResolver: FilePathResolver
) throws -> [String] {
    return try linkopts
        .map { linkopt in
            return try processLinkopt(
                linkopt,
                xcodeGeneratedFiles: xcodeGeneratedFiles,
                filePathResolver: filePathResolver
            )
        }
}

private func processLinkopt(
    _ linkopt: String,
    xcodeGeneratedFiles: Set<FilePath>,
    filePathResolver: FilePathResolver
) throws -> String {
    return try linkopt
        .split(separator: ",")
        .map(String.init)
        .map { opt in
            return try processLinkoptComponent(
                opt,
                xcodeGeneratedFiles: xcodeGeneratedFiles,
                filePathResolver: filePathResolver
            )
        }
        .joined(separator: ",")
}

private func processLinkoptComponent(
    _ opt: String,
    xcodeGeneratedFiles: Set<FilePath>,
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
        let xcodeGenerated = xcodeGeneratedFiles.contains(filePath)

        if xcodeGenerated {
            if let `extension` = filePath.path.extension,
               `extension` == "swiftmodule"
            {
                filePath = filePath + """
$(ARCHS)-$(LLVM_TARGET_TRIPLE_VENDOR)-$(SWIFT_PLATFORM_TARGET_PREFIX)$(LLVM_TARGET_TRIPLE_SUFFIX).swiftmodule
"""
            }
        }

        value = try filePathResolver
            .resolve(
                filePath,
                useOriginalGeneratedFiles:!xcodeGenerated
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
