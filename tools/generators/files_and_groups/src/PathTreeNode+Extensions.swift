import PBXProj

extension PathTreeNode {
    func splitExtension() -> (base: String, ext: String?) {
        guard let extIndex = name.lastIndex(of: ".") else {
            return (name, nil)
        }
        return (
            String(name[name.startIndex..<extIndex]),
            String(name[name.index(after: extIndex)..<name.endIndex])
        )
    }
}
