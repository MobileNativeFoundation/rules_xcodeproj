import PBXProj

extension String {
    func splitExtension() -> (base: String, ext: String?) {
        guard let extIndex = lastIndex(of: ".") else {
            return (self, nil)
        }
        return (
            String(self[startIndex..<extIndex]),
            String(self[index(after: extIndex)..<endIndex])
        )
    }
}
