import Foundation
import MixedLib

public let libResourcesString = "Hello, from Lib!"
public let mixedLibString = MixedLibObjC.mixedLibObjc()

private class ResourceHandle {}

public extension Bundle {
    static let libResources = Bundle(for: ResourceHandle.self)
}
