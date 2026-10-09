import Foundation

/// A type that assembles and writes to disk the `project.pbxproj` file from
/// `PBXProj` partials.
///
/// The `Generator` type is stateless. It can be used to assemble multiple
/// files. The `generate()` method is passed all the inputs needed to assemble
/// a file.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Assembles the `project.pbxproj` file and writes it to disk.
    func generate(arguments: Arguments) throws {
        let partials = try environment.readPartials(arguments.partials)
        try environment.write(arguments.outputPath) { write in
            try environment.assembleProjectPBXProj(partials, write)
        }
    }
}
