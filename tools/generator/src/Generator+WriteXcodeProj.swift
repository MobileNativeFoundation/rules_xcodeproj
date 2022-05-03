import PathKit
import XcodeProj

extension Generator {
    /// Writes the ".xcodeproj" file to disk.
    static func writeXcodeProj(
        _ xcodeProj: XcodeProj,
        buildMode: BuildMode,
        files: [FilePath: File],
        internalDirectoryName: String,
        stubsPath: Path,
        to outputPath: Path
    ) throws {
        try xcodeProj.write(path: outputPath)

        let internalOutputPath = outputPath + internalDirectoryName

        for (filePath, file) in files.filter(\.key.isInternal) {
            guard case let .reference(_, maybeContent) = file else {
                continue
            }
            guard let content = maybeContent else {
                continue
            }
            
            let path = internalOutputPath + filePath.path
            try path.parent().mkpath()
            try path.write(content)
        }

        if buildMode.usesBazelModeBuildScripts {
            let dest = internalOutputPath + "stubs"
            try stubsPath.copy(dest)
        }
    }
}

private extension FilePath {
    var isInternal: Bool { type == .internal }
}
