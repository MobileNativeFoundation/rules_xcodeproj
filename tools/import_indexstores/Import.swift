import Foundation

extension ImportIndex {
    static func `import`(
        _ indexstores: Set<String>,
        into indexDataStoreDir: URL,
        arch: String,
        developerDir: String,
        indexImport: String,
        objectFilePrefix: String,
        projectDirPrefix: String,
        srcRoot: String,
        targetPathOverride: String?,
        xcodeExecutionRoot: String,
        xcodeOutputBase: String
    ) throws {
        let filelistContent = indexstores
            .map { projectDirPrefix + $0 + "\n" }
            .joined()

        let filelist = try TemporaryFile()
        try filelistContent
            .write(to: filelist.url, atomically: true, encoding: .utf8)

        let remaps = remapArgs(
            arch: arch,
            developerDir: developerDir,
            objectFilePrefix: objectFilePrefix,
            srcRoot: srcRoot,
            targetPathOverride: targetPathOverride,
            xcodeExecutionRoot: xcodeExecutionRoot,
            xcodeOutputBase: xcodeOutputBase
        )

        try runSubProcess(
            indexImport,
            remaps + [
                "-undo-rules_swift-renames",
                "-incremental",
                "@\(filelist.url.path)",
                indexDataStoreDir.path,
            ]
        )
    }
}
