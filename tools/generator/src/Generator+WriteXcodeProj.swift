import PathKit
import XcodeProj

extension Generator {
    /// Writes the ".xcodeproj" file to disk.
    static func writeXcodeProj(
        _ xcodeProj: XcodeProj,
        files: [FilePath: File],
        internalDirectoryName: String,
        to outputPath: Path
    ) throws {
        try xcodeProj.write(path: outputPath)

        let internalOutputPath = outputPath + internalDirectoryName

        for (filePath, file) in files.filter(\.key.isInternal) {
            let path = internalOutputPath + filePath.path
            try path.parent().mkpath()
            try path.write(file.content)
        }
    }
}

private extension FilePath {
    var isInternal: Bool { type == .internal }
}
