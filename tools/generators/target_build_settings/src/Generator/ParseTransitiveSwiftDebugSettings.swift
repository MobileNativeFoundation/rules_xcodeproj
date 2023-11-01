import Foundation
import OrderedCollections
import PBXProj
import ToolCommon

extension Generator {
    struct ParseTransitiveSwiftDebugSettings {
        private let readTargetSwiftDebugSettingsFile:
            ReadTargetSwiftDebugSettingsFile

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            readTargetSwiftDebugSettingsFile: ReadTargetSwiftDebugSettingsFile,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.readTargetSwiftDebugSettingsFile =
                readTargetSwiftDebugSettingsFile

            self.callable = callable
        }

        /// Reads transitive Swift debug settings to set Swift debug settings
        /// for the current target.
        func callAsFunction(
            _ transitiveSwiftDebugSettingPaths: [URL],
            clangArgs: inout [String],
            frameworkIncludes: inout OrderedSet<String>,
            onceClangArgs: inout Set<String>,
            swiftIncludes: inout OrderedSet<String>
        ) async throws {
            try await callable(
                /*transitiveSwiftDebugSettingPaths:*/
                    transitiveSwiftDebugSettingPaths,
                /*clangArgs:*/ &clangArgs,
                /*frameworkIncludes:*/ &frameworkIncludes,
                /*onceClangArgs:*/ &onceClangArgs,
                /*swiftIncludes:*/ &swiftIncludes,
                /*readTargetSwiftDebugSettingsFile:*/
                    readTargetSwiftDebugSettingsFile
            )
        }
    }
}

// MARK: - ParseTransitiveSwiftDebugSettings.Callable

extension Generator.ParseTransitiveSwiftDebugSettings {
    typealias Callable = (
        _ transitiveSwiftDebugSettingPaths: [URL],
        _ clangArgs: inout [String],
        _ frameworkIncludes: inout OrderedSet<String>,
        _ onceClangArgs: inout Set<String>,
        _ swiftIncludes: inout OrderedSet<String>,
        _ readTargetSwiftDebugSettingsFile: ReadTargetSwiftDebugSettingsFile
    ) async throws -> Void

    static func defaultCallable(
        _ transitiveSwiftDebugSettingPaths: [URL],
        clangArgs: inout [String],
        frameworkIncludes: inout OrderedSet<String>,
        onceClangArgs: inout Set<String>,
        swiftIncludes: inout OrderedSet<String>,
        readTargetSwiftDebugSettingsFile: ReadTargetSwiftDebugSettingsFile
    ) async throws {
        for url in transitiveSwiftDebugSettingPaths {
            let swiftDebugSettings =
                try await readTargetSwiftDebugSettingsFile(from: url)

            frameworkIncludes.formUnion(swiftDebugSettings.frameworkIncludes)
            swiftIncludes.formUnion(swiftDebugSettings.swiftIncludes)

            argsLoop: for arg in swiftDebugSettings.clangArgs {
                for onceArgPrefixes in clangOnceArgPrefixes {
                    if arg.hasPrefix(onceArgPrefixes) {
                        guard !onceClangArgs.contains(arg) else {
                            continue argsLoop
                        }
                        onceClangArgs.insert(arg)
                        break
                    }
                }
                clangArgs.append(arg)
            }
        }
    }
}

private let clangOnceArgPrefixes = [
    "-F",
    "-D",
    "-I",
    "-fmodule-map-file=",
    "-ivfsoverlay",
]
