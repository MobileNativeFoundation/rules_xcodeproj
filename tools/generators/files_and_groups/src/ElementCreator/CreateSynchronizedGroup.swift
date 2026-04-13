import Foundation
import PBXProj

extension ElementCreator {
    struct CreateSynchronizedGroup {
        private let createAttributes: CreateAttributes
        private let installPath: String
        private let workspace: String

        init(
            createAttributes: CreateAttributes,
            installPath: String,
            workspace: String
        ) {
            self.createAttributes = createAttributes
            self.installPath = installPath
            self.workspace = workspace
        }

        func callAsFunction(
            name: String,
            synchronizedFolder: PathTreeNode.SynchronizedFolder,
            bazelPathType: BazelPathType,
            forceWorkspaceRooted: Bool = false
        ) -> GroupChild.ElementAndChildren {
            let bazelPath = synchronizedFolder.path
            let attributes: ElementAttributes
            if forceWorkspaceRooted {
                attributes = .init(
                    sourceTree: .sourceRoot,
                    name: name,
                    path: bazelPath.path
                )
            } else {
                attributes = createAttributes(
                    name: name,
                    bazelPath: bazelPath,
                    bazelPathType: bazelPathType,
                    isGroup: true
                ).elementAttributes
            }

            let folderURL = URL(fileURLWithPath: workspace, isDirectory: true)
                .appendingPathComponent(bazelPath.path, isDirectory: true)
            let relativeFolderPaths: Set<String>
            do {
                relativeFolderPaths = try self.relativeFolderPaths(
                    in: folderURL,
                    ignoredRelativePathPrefix: relativePath(
                        BazelPath(installPath),
                        under: bazelPath
                    )
                )
            } catch {
                writeEnumerationWarning(for: bazelPath, error: error)
                relativeFolderPaths = []
            }

            var exceptionIdentifiers: [String] = []
            var exceptionObjects: [Object] = []
            for target in synchronizedFolder.targets {
                let membershipExceptions = membershipExceptions(
                    for: target,
                    relativeFolderPaths: relativeFolderPaths
                )
                guard !membershipExceptions.isEmpty else {
                    continue
                }

                let identifier = Identifiers.FilesAndGroups
                    .synchronizedBuildFileExceptionSet(
                        path: bazelPath.path,
                        targetIdentifier: target.targetIdentifier
                    )
                exceptionIdentifiers.append(identifier)

                let content = #"""
{
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
\#(membershipExceptions.map { "\t\t\t\t\($0.pbxProjEscaped),\n" }.joined())\#
			);
			target = \#(target.targetIdentifier);
		}
"""#

                exceptionObjects.append(
                    .init(identifier: identifier, content: content)
                )
            }

            let content: String
            let nameAttribute: String
            if let name = attributes.name {
                nameAttribute = #"""
			name = \#(name.pbxProjEscaped);

"""#
            } else {
                nameAttribute = ""
            }
            if exceptionIdentifiers.isEmpty {
                content = #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
\#(nameAttribute)\#
			path = \#(attributes.path.pbxProjEscaped);
			sourceTree = \#(attributes.sourceTree.rawValue);
		}
"""#
            } else {
                content = #"""
{
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
\#(exceptionIdentifiers.map { "\t\t\t\t\($0),\n" }.joined())\#
			);
\#(nameAttribute)\#
			path = \#(attributes.path.pbxProjEscaped);
			sourceTree = \#(attributes.sourceTree.rawValue);
		}
"""#
            }

            let identifier = Identifiers.FilesAndGroups.synchronizedRootGroup(
                bazelPath.path,
                name: name
            )
            let groupObject = Object(identifier: identifier, content: content)

            return .init(
                element: .init(
                    name: name,
                    object: groupObject,
                    sortOrder: .groupLike
                ),
                transitiveObjects: exceptionObjects + [groupObject],
                bazelPathAndIdentifiers: [(bazelPath, identifier)],
                knownRegions: [],
                resolvedRepositories: []
            )
        }

        private func relativeFolderPaths(
            in url: URL,
            ignoredRelativePathPrefix: String?
        ) throws -> Set<String> {
            let normalizedFolderURL = url
                .resolvingSymlinksInPath()
                .standardizedFileURL

            guard FileManager.default.fileExists(atPath: normalizedFolderURL.path)
            else {
                return []
            }

            let enumerator = FileManager.default.enumerator(
                at: normalizedFolderURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            let prefix = "\(normalizedFolderURL.path)/"
            var paths: Set<String> = []
            while let childURL = enumerator?.nextObject() as? URL {
                let normalizedChildURL = childURL
                    .resolvingSymlinksInPath()
                    .standardizedFileURL
                guard normalizedChildURL.path.hasPrefix(prefix) else {
                    continue
                }
                let relativePath = String(
                    normalizedChildURL.path.dropFirst(prefix.count)
                )

                if let ignoredRelativePathPrefix,
                   relativePath == ignoredRelativePathPrefix ||
                    relativePath.hasPrefix("\(ignoredRelativePathPrefix)/")
                {
                    let values = try childURL.resourceValues(forKeys: [.isDirectoryKey])
                    if values.isDirectory == true {
                        enumerator?.skipDescendants()
                    }
                    continue
                }

                let values = try childURL.resourceValues(forKeys: [.isDirectoryKey])
                guard values.isDirectory != true else {
                    continue
                }
                paths.insert(relativePath)
            }

            return paths
        }

        private func membershipExceptions(
            for target: SynchronizedFolderTarget,
            relativeFolderPaths: Set<String>
        ) -> [String] {
            let includedPaths = Set(
                target.includedPaths.compactMap {
                    relativePath($0, under: target.folderPath)
                }
            )
            let excludedPaths = Set(
                target.excludedPaths.compactMap {
                    relativePath($0, under: target.folderPath)
                }
            )

            return relativeFolderPaths
                .filter { relativeFolderPath in
                    !containsPathOrDescendant(
                        relativeFolderPath,
                        in: includedPaths
                    ) || containsPathOrDescendant(
                        relativeFolderPath,
                        in: excludedPaths
                    )
                }
                .sorted()
        }

        private func relativePath(
            _ path: BazelPath,
            under folder: BazelPath
        ) -> String? {
            if path.path == folder.path {
                return nil
            }
            let prefix = "\(folder.path)/"
            guard path.path.hasPrefix(prefix) else {
                return nil
            }
            return String(path.path.dropFirst(prefix.count))
        }

        private func containsPathOrDescendant(
            _ relativeFolderPath: String,
            in paths: Set<String>
        ) -> Bool {
            return paths.contains { path in
                relativeFolderPath == path ||
                    relativeFolderPath.hasPrefix("\(path)/")
            }
        }

        private func writeEnumerationWarning(
            for folder: BazelPath,
            error: Error
        ) {
            let warning = """
warning: failed to enumerate synchronized folder '\(folder.path)': \
\(error.localizedDescription)

"""
            FileHandle.standardError.write(Data(warning.utf8))
        }
    }
}
