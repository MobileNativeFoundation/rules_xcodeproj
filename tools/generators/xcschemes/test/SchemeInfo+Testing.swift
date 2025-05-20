import XCScheme

@testable import xcschemes

extension SchemeInfo {
    static func mock(
        name: String,
        test: Test = .mock(),
        run: Run = .mock(),
        profile: Profile = .mock(),
        executionActions: [SchemeInfo.ExecutionAction] = []
    ) -> Self {
        return Self(
            name: name,
            test: test,
            run: run,
            profile: profile,
            executionActions: executionActions
        )
    }
}

extension SchemeInfo.Profile {
    static func mock(
        buildTargets: [Target] = [],
        commandLineArguments: [CommandLineArgument] = [],
        customWorkingDirectory: String? = nil,
        environmentVariables: [EnvironmentVariable] = [],
        launchTarget: SchemeInfo.LaunchTarget? = nil,
        useRunArgsAndEnv: Bool = true,
        xcodeConfiguration: String? = nil
    ) -> Self {
        return Self(
            buildTargets: buildTargets,
            commandLineArguments: commandLineArguments,
            customWorkingDirectory: customWorkingDirectory,
            environmentVariables: environmentVariables,
            launchTarget: launchTarget,
            useRunArgsAndEnv: useRunArgsAndEnv,
            xcodeConfiguration: xcodeConfiguration
        )
    }
}

extension SchemeInfo.Run {
    static func mock(
        buildTargets: [Target] = [],
        commandLineArguments: [CommandLineArgument] = [],
        customWorkingDirectory: String? = nil,
        enableMainThreadChecker: Bool = false,
        enableThreadPerformanceChecker: Bool = false,
        enableAddressSanitizer: Bool = false,
        enableThreadSanitizer: Bool = false,
        enableUBSanitizer: Bool = false,
        storeKitConfiguration: String? = nil,
        environmentVariables: [EnvironmentVariable] = [],
        launchTarget: SchemeInfo.LaunchTarget? = nil,
        xcodeConfiguration: String? = nil
    ) -> Self {
        return Self(
            buildTargets: buildTargets,
            commandLineArguments: commandLineArguments,
            customWorkingDirectory: customWorkingDirectory,
            enableAddressSanitizer: enableAddressSanitizer,
            enableThreadSanitizer: enableThreadSanitizer,
            enableUBSanitizer: enableUBSanitizer,
            enableMainThreadChecker: enableMainThreadChecker,
            enableThreadPerformanceChecker: enableThreadPerformanceChecker,
            storeKitConfiguration: storeKitConfiguration,
            environmentVariables: environmentVariables,
            launchTarget: launchTarget,
            xcodeConfiguration: xcodeConfiguration
        )
    }
}

extension SchemeInfo.Test {
    static func mock(
        buildTargets: [Target] = [],
        commandLineArguments: [CommandLineArgument] = [],
        customWorkingDirectory: String? = nil,
        enableAddressSanitizer: Bool = false,
        enableThreadSanitizer: Bool = false,
        enableUBSanitizer: Bool = false,
        enableMainThreadChecker: Bool = false,
        enableThreadPerformanceChecker: Bool = false,
        environmentVariables: [EnvironmentVariable] = [],
        options: SchemeInfo.Test.Options = .init(appLanguage: nil, appRegion: nil),
        testTargets: [SchemeInfo.TestTarget] = [],
        useRunArgsAndEnv: Bool = true,
        xcodeConfiguration: String? = nil
    ) -> Self {
        return Self(
            buildTargets: buildTargets,
            commandLineArguments: commandLineArguments,
            enableAddressSanitizer: enableAddressSanitizer,
            enableThreadSanitizer: enableThreadSanitizer,
            enableUBSanitizer: enableUBSanitizer,
            enableMainThreadChecker: enableMainThreadChecker,
            enableThreadPerformanceChecker: enableThreadPerformanceChecker,
            environmentVariables: environmentVariables,
            options: options,
            testTargets: testTargets,
            useRunArgsAndEnv: useRunArgsAndEnv,
            xcodeConfiguration: xcodeConfiguration
        )
    }
}
