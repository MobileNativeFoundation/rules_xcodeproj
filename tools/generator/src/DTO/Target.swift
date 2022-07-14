import PathKit

struct Target: Equatable, Decodable {
    let name: String
    let label: BazelLabel
    let configuration: String
    var packageBinDir: Path
    let platform: Platform
    let product: Product
    var isSwift: Bool
    let testHost: TargetID?
    var buildSettings: [String: BuildSetting]
    var searchPaths: SearchPaths
    var modulemaps: [FilePath]
    var swiftmodules: [FilePath]
    var inputs: Inputs
    var linkerInputs: LinkerInputs
    var infoPlist: FilePath?
    var entitlements: FilePath?
    let resourceBundleDependencies: Set<TargetID>
    let watchApplication: TargetID?
    let extensions: Set<TargetID>
    let appClips: Set<TargetID>
    var dependencies: Set<TargetID>
    var outputs: Outputs
}

extension Target {
    var allDependencies: Set<TargetID> {
        return dependencies.union(resourceBundleDependencies)
    }

    var hasLinkerFlags: Bool {
        return !linkerInputs.linkopts.isEmpty
            || !linkerInputs.staticLibraries.isEmpty
            || !inputs.exportedSymbolsLists.isEmpty
            || !linkerInputs.forceLoad.isEmpty
    }

    func allLinkerFlags(filePathResolver: FilePathResolver) throws -> [String] {
        var flags = linkerInputs.linkopts

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
