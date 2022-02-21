@testable import XcodeProj

extension PBXProj {
    /// Converts temporary references into stable ones, for equality asserts.
    func fixReferences() throws {
        let referenceGenerator = ReferenceGenerator(outputSettings: .init())
        try referenceGenerator.generateReferences(proj: self)
    }
}
