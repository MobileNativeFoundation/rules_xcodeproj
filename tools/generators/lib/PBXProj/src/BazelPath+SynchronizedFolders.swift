extension Array where Element == BazelPath {
    /// Removes the paths inside `synchronizedFolders`, whose contents Xcode
    /// shows and adds to targets on its own.
    public func removingPaths(
        inSynchronizedFolders synchronizedFolders: Set<BazelPath>
    ) -> [BazelPath] {
        guard !synchronizedFolders.isEmpty else {
            return self
        }
        return filter { path in
            var components = path.path.split(separator: "/")
            guard !components.isEmpty else {
                return true
            }
            components.removeLast()
            while !components.isEmpty {
                if synchronizedFolders.contains(
                    BazelPath(components.joined(separator: "/"))
                ) {
                    return false
                }
                components.removeLast()
            }
            return true
        }
    }
}
