@testable import XcodeProj

extension PBXProj {
    /// Converts temporary references into stable ones, for equality asserts.
    func fixReferences() throws {
        let referenceGenerator = ReferenceGenerator(outputSettings: .init())
        try referenceGenerator.generateReferences(proj: self)

        // `PBXProject.targetAttributes` can contain `PBXObject`s. Equality
        // checks for those fail, so we do the conversion that happens in
        // `PBXProject: PlistSerializable`.
        rootObject!.targetAttributeReferences = rootObject!
            .targetAttributeReferences.mapValues { attributes in
                return attributes.mapValues { value in
                    return (value as? PBXObject)?.reference.value ?? value
                }
            }
    }
}
