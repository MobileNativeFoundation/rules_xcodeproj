import PBXProj

func groupedSynchronizedFolders(
    _ synchronizedFolders: [SynchronizedFolderTarget]
) -> [PathTreeNode.SynchronizedFolder] {
    return Dictionary(grouping: synchronizedFolders, by: \.folderPath)
        .map { path, targets in
            PathTreeNode.SynchronizedFolder(
                path: path,
                targets: targets.sorted { lhs, rhs in
                    lhs.targetName < rhs.targetName
                }
            )
        }
        .sorted { lhs, rhs in
            lhs.path < rhs.path
        }
}

func synchronizedFolderName(for path: BazelPath) -> String {
    return path.path.split(separator: "/").last.map(String.init) ?? path.path
}

func isPathDescendant(_ path: String, of folder: String) -> Bool {
    return path == folder || path.hasPrefix("\(folder)/")
}
