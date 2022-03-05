import PathKit
import XcodeProj

extension Generator {
    ///
    static func writeXcodeProj(
        _ xcodeProj: XcodeProj,
        files: [FilePath: PBXFileElement],
        internalDirectoryName: String,
        to outputPath: Path
    ) throws {
        try xcodeProj.write(path: outputPath)

        let internalOutputPath = outputPath + internalDirectoryName

        // This will have to be improved when we eventually write different
        // types of internal files
        for (filePath, fileElement) in files.filter(\.key.isInternal) {
            let path = internalOutputPath + filePath.path
            if fileElement is PBXGroup {
                try path.mkpath()
            } else {
                try path.parent().mkpath()
                try path.write("")
            }
        }
    }
}

private extension FilePath {
    var isInternal: Bool { type == .internal }
}
