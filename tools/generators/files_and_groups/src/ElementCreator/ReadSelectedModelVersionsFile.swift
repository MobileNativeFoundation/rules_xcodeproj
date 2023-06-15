import Foundation
import GeneratorCommon
import PBXProj

extension ElementCreator {
    #Injectable(asStatic: true) {
        /// Reads the file at `url`, returning a mapping of `.xcdatamodeld`
        /// file paths to selected `.xcdatamodel` file names.
        func readSelectedModelVersionsFile(
            _ url: URL
        ) throws -> [BazelPath: String] {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(
                [BazelPath: BazelPath].self,
                from: Data(contentsOf: url)
            )
        }
    }
}
