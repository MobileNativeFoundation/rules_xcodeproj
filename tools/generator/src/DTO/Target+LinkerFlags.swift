import PathKit

extension Target {
    var hasLinkerFlags: Bool {
        return !linkerInputs.linkopts.isEmpty
            || !inputs.exportedSymbolsLists.isEmpty
            || !linkerInputs.forceLoad.isEmpty
    }

    func allLinkerFlags(filePathResolver: FilePathResolver) -> [String] {
        var flags = linkerInputs.linkopts

        func handleFilePath(_ filePath: FilePath) -> String {
            return filePathResolver.resolve(filePath).string.quoted
        }

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
