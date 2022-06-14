import XcodeProj

extension PBXGroup {
    func addChild(_ child: PBXFileElement) {
        children.append(child)
        child.parent = self
    }

    func addChildren<S>(_ children: S)
    where S: Sequence, S.Element == PBXFileElement {
        self.children.append(contentsOf: children)
        children.forEach { $0.parent = self }
    }
}
