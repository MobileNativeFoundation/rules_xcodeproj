import XcodeProj

extension Generator {
    /// Creates an `XCSharedData`.
    static func createXCSharedData(schemes: [XCScheme]) -> XCSharedData {
        XCSharedData(schemes: schemes)
    }
}
