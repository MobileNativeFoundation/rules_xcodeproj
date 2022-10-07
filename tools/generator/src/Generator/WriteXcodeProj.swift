import PathKit
import XcodeProj

extension Generator {
    /// Writes the ".xcodeproj" file to disk.
    static func writeXcodeProj(
        _ xcodeProj: XcodeProj,
        directories: FilePathResolver.Directories,
        files: [FilePath: File],
        to outputPath: Path
    ) throws {
        try xcodeProj.write(path: outputPath)

        let internalOutputPath = outputPath + directories.internalDirectoryName

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

        let dest = internalOutputPath + "bazel"
        try internalOutputPath.mkpath()
        try directories.bazelIntegration.copy(dest)
    }
}

private extension FilePath {
    var isInternal: Bool { type == .internal }
}
