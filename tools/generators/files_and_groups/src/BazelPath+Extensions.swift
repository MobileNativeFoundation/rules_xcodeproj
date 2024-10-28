import PBXProj

extension BazelPath {
    init(parent: BazelPath, path: String) {
        let newPath: String
        if parent.path.isEmpty {
            newPath = path
        } else {
            newPath = "\(parent.path)/\(path)"
        }

        self.init(newPath)
    }
}
