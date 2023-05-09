import PathKit
import XcodeProj

extension Generator {
    /// Writes the ".xcodeproj" file to disk.
    static func writeXcodeProj(
        _ xcodeProj: XcodeProj,
        directories: Directories,
        internalFiles: [Path: String],
        to outputPath: Path
    ) throws {
        try xcodeProj.write(path: outputPath)

        let internalOutputPath = outputPath + directories.internalDirectoryName

        for (file, content) in internalFiles {
            let path = internalOutputPath + file
            try path.parent().mkpath()
            try path.write(content)
        }
    }
}
