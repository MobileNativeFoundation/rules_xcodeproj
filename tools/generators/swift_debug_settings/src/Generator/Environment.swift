import PBXProj

extension Generator {
    struct Environment {
        let readKeyedSwiftDebugSettings: ReadKeyedSwiftDebugSettings
        let writeSwiftDebugSettings: WriteSwiftDebugSettings
    }
}

extension Generator.Environment {
    static let `default` = Self(
        readKeyedSwiftDebugSettings: Generator.ReadKeyedSwiftDebugSettings(
            readTargetSwiftDebugSettingsFile: ReadTargetSwiftDebugSettingsFile()
        ),
        writeSwiftDebugSettings: Generator.WriteSwiftDebugSettings(
            write: Write()
        )
    )
}
