import Foundation
import PBXProj

extension Generator {
    struct WriteSchemes {
        private let createScheme: CreateScheme
        private let write: Write

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createScheme: CreateScheme,
            write: Write,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createScheme = createScheme
            self.write = write

            self.callable = callable
        }

        /// Creates and writes `.xcscheme`s to disk.
        func callAsFunction(
            defaultXcodeConfiguration: String,
            extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
            schemeInfos: [SchemeInfo],
            to outputDirectory: URL
        ) async throws {
            try await callable(
                /*defaultXcodeConfiguration:*/ defaultXcodeConfiguration,
                /*extensionPointIdentifiers:*/ extensionPointIdentifiers,
                /*outputDirectory:*/ outputDirectory,
                /*schemeInfos:*/ schemeInfos,
                /*createScheme:*/ createScheme,
                /*write:*/ write
            )
        }
    }
}

// MARK: - WriteSchemes.Callable

extension Generator.WriteSchemes {
    typealias Callable = (
        _ defaultXcodeConfiguration: String,
        _ extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        _ outputDirectory: URL,
        _ schemeInfos: [SchemeInfo],
        _ createScheme: Generator.CreateScheme,
        _ write: Write
    ) async throws -> Void

    static func defaultCallable(
        defaultXcodeConfiguration: String,
        extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        outputDirectory: URL,
        schemeInfos: [SchemeInfo],
        createScheme: Generator.CreateScheme,
        write: Write
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for schemeInfo in schemeInfos {
                group.addTask {
                    let (name, scheme) = try createScheme(
                        defaultXcodeConfiguration: defaultXcodeConfiguration,
                        extensionPointIdentifiers: extensionPointIdentifiers,
                        schemeInfo: schemeInfo
                    )

                    try write(
                        scheme,
                        to: outputDirectory.appending(path: "\(name).xcscheme")
                    )
                }
            }

            try await group.waitForAll()
        }
    }
}
