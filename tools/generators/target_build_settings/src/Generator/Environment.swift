import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let processArgs: ProcessArgs
        let writeBuildSettings: WriteBuildSettings
        let writeTargetSwiftDebugSettings: WriteTargetSwiftDebugSettings
    }
}

extension Generator.Environment {
    static let `default` = {
        let processCcArg = Generator.ProcessCcArg()
        let write = Write()

        return Self(
            processArgs: Generator.ProcessArgs(
                processCArgs: Generator.ProcessCArgs(
                    processCcArgs: Generator.ProcessCcArgs(
                        processCcArg: processCcArg
                    ),
                    write: write
                ),
                processCxxArgs: Generator.ProcessCxxArgs(
                    processCcArgs: Generator.ProcessCcArgs(
                        processCcArg: processCcArg
                    ),
                    write: write
                ),
                processSwiftArgs: Generator.ProcessSwiftArgs(
                    parseTransitiveSwiftDebugSettings:
                        Generator.ParseTransitiveSwiftDebugSettings(
                            readTargetSwiftDebugSettingsFile:
                                ReadTargetSwiftDebugSettingsFile()
                        ),
                    processSwiftArg: Generator.ProcessSwiftArg(),
                    processSwiftClangArg: Generator.ProcessSwiftClangArg(),
                    processSwiftFrontendArg: Generator.ProcessSwiftFrontendArg()
                )
            ),
            writeBuildSettings: Generator.WriteBuildSettings(),
            writeTargetSwiftDebugSettings: WriteTargetSwiftDebugSettings()
        )
    }()
}
