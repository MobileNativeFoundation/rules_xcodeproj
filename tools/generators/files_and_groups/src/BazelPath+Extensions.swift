import PBXProj

/// Appends a path fragment to a `BazelPath` to produce a new `BazelPath`.
func +(lhs: BazelPath, rhs: PathTreeNode) -> BazelPath {
    return BazelPath(
        "\(lhs.path)/\(rhs.name)",
        isFolder: rhs.isFolder
    )
}
