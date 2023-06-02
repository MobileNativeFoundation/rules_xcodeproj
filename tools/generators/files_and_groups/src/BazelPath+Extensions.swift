import PBXProj

/// Appends a path fragment to a `BazelPath` to produce a new `BazelPath`.
func +(lhs: BazelPath, rhs: PathTreeNode) -> BazelPath {
    let path: String
    if lhs.path.isEmpty {
        path = rhs.name
    } else {
        path = "\(lhs.path)/\(rhs.name)"
    }

    return BazelPath(
        path,
        isFolder: rhs.isFolder
    )
}
