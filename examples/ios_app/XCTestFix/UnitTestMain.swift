import ObjectiveC

final class UnitTestMain: NSObject {
    override init() {
        super.init()

        swizzleXCTSourceCodeLocationIfNeeded()
    }
}
