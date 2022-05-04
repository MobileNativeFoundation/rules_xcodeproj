import XcodeProj

extension Dictionary where Value: PBXTarget {
    func nativeTarget(_ targetID: Self.Key) -> PBXNativeTarget? {
        return self[targetID] as? PBXNativeTarget
    }
}
