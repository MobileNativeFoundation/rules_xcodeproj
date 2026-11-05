import Foundation

extension Generator {
    struct Environment {
        let assembleProjectPBXProj: (
            _ partials: [UInt8],
            _ write: WriteBytes
        ) throws -> Void

        let readPartials: (_ urls: [URL]) throws -> [UInt8]

        let write: (
            _ url: URL,
            _ body: (_ write: WriteBytes) throws -> Void
        ) throws -> Void
    }
}

extension Generator.Environment {
    static let `default` = Self(
        assembleProjectPBXProj: Generator.assembleProjectPBXProj,
        readPartials: Generator.readPartials,
        write: Generator.write
    )
}
