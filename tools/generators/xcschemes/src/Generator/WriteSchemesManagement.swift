import Foundation
import PBXProj
import XCScheme

extension Generator {
    struct WriteSchemeManagement {
        private let createSchemeManagement: CreateSchemeManagement
        private let write: Write

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createSchemeManagement: CreateSchemeManagement,
            write: Write,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createSchemeManagement = createSchemeManagement
            self.write = write

            self.callable = callable
        }

        /// Creates and writes a `xcschememanagement.plist` file to disk.
        func callAsFunction(
            schemeNames: [String],
            to outputPath: URL
        ) async throws {
            try await callable(
                /*outputPath:*/ outputPath,
                /*schemeNames:*/ schemeNames,
                /*createSchemeManagement:*/ createSchemeManagement,
                /*write:*/ write
            )
        }
    }
}

// MARK: - WriteSchemeManagement.Callable

extension Generator.WriteSchemeManagement {
    typealias Callable = (
        _ outputPath: URL,
        _ schemeNames: [String],
        _ createSchemeManagement: CreateSchemeManagement,
        _ write: Write
    ) async throws -> Void

    static func defaultCallable(
        outputPath: URL,
        schemeNames: [String],
        createSchemeManagement: CreateSchemeManagement,
        write: Write
    ) async throws {
        try write(
            createSchemeManagement(schemeNames: schemeNames),
            to: outputPath
        )
    }
}
