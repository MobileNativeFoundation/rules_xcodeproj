public extension BazelPath {
    func isContained(in folders: [BazelPath]) -> Bool {
        for folder in folders {
            if path == folder.path || path.hasPrefix("\(folder.path)/") {
                return true
            }
        }
        return false
    }
}
