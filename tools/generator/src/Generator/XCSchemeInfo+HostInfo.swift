import XcodeProj

extension XCSchemeInfo {
    struct HostInfo: Equatable, Hashable {
        let pbxTarget: PBXTarget
        // The platforms property is a sorted list of unique platforms.
        let platforms: [Platform]
        let buildableReference: XCScheme.BuildableReference
        let index: Int

        init<Platforms: Sequence>(
            pbxTarget: PBXTarget,
            platforms: Platforms,
            buildableReference: XCScheme.BuildableReference,
            index: Int
        ) where Platforms.Element == Platform {
             self.pbxTarget = pbxTarget
             self.platforms = Set(platforms).sorted()
             self.buildableReference = buildableReference
             self.index = index
        }
    }
}

// MARK: Initializers

extension XCSchemeInfo.HostInfo {
    init<Platforms: Sequence>(
        pbxTarget: PBXTarget,
        platforms: Platforms,
        referencedContainer: String,
        index: Int
    ) where Platforms.Element == Platform {
        self.init(
            pbxTarget: pbxTarget,
            platforms: platforms,
            buildableReference: .init(
                pbxTarget: pbxTarget,
                referencedContainer: referencedContainer
            ),
            index: index
        )
    }
}

extension XCSchemeInfo.HostInfo {
    init(pbxTargetInfo: TargetResolver.PBXTargetInfo, index: Int) {
        self.init(
            pbxTarget: pbxTargetInfo.pbxTarget,
            platforms: pbxTargetInfo.platforms,
            buildableReference: pbxTargetInfo.buildableReference,
            index: index
        )
    }
}

// MARK: `Comparable`

extension XCSchemeInfo.HostInfo: Comparable {
    static func < (lhs: XCSchemeInfo.HostInfo, rhs: XCSchemeInfo.HostInfo) -> Bool {
        // The platforms for HostInfo are sorted with the preferred/best platform first.
        // Sort HostInfo instances based upon the best platform
        guard let lhsFirstPlatform = lhs.platforms.first else {
            return false
        }
        guard let rhsFirstPlatform = rhs.platforms.first else {
            return true
        }
        return lhsFirstPlatform < rhsFirstPlatform
    }
}
