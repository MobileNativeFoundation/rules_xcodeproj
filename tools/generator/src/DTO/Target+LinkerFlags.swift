import PathKit

extension Target {
    var hasLinkerFlags: Bool {
        return !linkerInputs.linkopts.isEmpty
            || !inputs.exportedSymbolsLists.isEmpty
    }

    func allLinkerFlags(filePathResolver: FilePathResolver) -> [String] {
        var flags = linkerInputs.linkopts

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
