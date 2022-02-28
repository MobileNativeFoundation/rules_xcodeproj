import XcodeProj

extension Generator {
    /// Sets the main group's children.
    static func populateMainGroup(
        _ mainGroup: PBXGroup,
        in pbxProj: PBXProj,
        rootElements: [PBXFileElement],
        productsGroup: PBXGroup
    ) {
        mainGroup.children = []
        mainGroup.addChildren(rootElements)

        // If the "Products" group is the last in the list (so after Frameworks)
        // Xcode won't show it... 
        // https://developer.apple.com/forums/thread/77406?answerId=703020022#703020022
        // So we have the products before the Frameworks group.
        mainGroup.addChild(productsGroup)

        // TODO: Only add if there are frameworks (this matches Xcode behavior)
        let frameworksGroup = PBXGroup(sourceTree: .group, name: "Frameworks")
        pbxProj.add(object: frameworksGroup)
        mainGroup.addChild(frameworksGroup)
    }
}
