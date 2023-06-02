# Files and groups `PBXProj` partials generator

The `files_and_groups` generator creates three files:

- A `PBXProj` partial containing the `PBXProject.knownRegions` property
- A `PBXProj` partial containing:
	- `PBXFileReference`s
	- `PBXGroup`s
	- `PBXBuildFile`s
	- Closes the `PBXProj` element
- A file containing a string for the `RESOLVED_REPOSITORIES` build setting

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`FilesAndGroups.swift`](src/FilesAndGroups.swift) for more details):

- Positional `known-regions-output-path`
- Positional `files-and-groups-output-path`
- Positional `resolved-repositories-output-path`
- Positional `workspace`
- Positional `execution-root-file`
- Positional `development-region`
- Flag `--use-base-internationalization`
- Optional option list `--file-paths <file-path> ...`
- Optional option list `--folder-paths <folder-path> ...`
- Flag `--colorize`

Here is an example invocation:

```shell
$ files_and_groups \
    /tmp/pbxproj_partials/pbxproject_known_regions \
    /tmp/pbxproj_partials/files_and_groups \
    /tmp/pbxproj_partials/resolved_repositories \
    /tmp/workspace \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/xcodeproj/xcodeproj_execution_root_file \
	en \
	--use-base-internationalization \
	--file-paths \
	a/project/file \
	bazel-out/generated/file \
	external/repository/file \
	--folder-paths \
	a/project/structure/resource/folder
```

## Output

Here is an example output:

### `pbxproject_known_regions`

```
			knownRegions = (
				en,
				Base,
			);

```

### `files_and_groups`

```

```

### `resolved_repositories`

```
"." "/tmp/workspace" "./external/a/b" "/ex/a/b"

```
