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
- Positional `selected-model-versions-file`
- Positional `development-region`
- Flag `--use-base-internationalization`
- Flag `--compile-stub-needed`
- Option list `--build-file-sub-identifiers-files <build-file-sub-identifiers-file> ...`
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
    some/project.xcodeproj \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/xcodeproj/xcodeproj_execution_root_file \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/xcodeproj/xcodeproj_selected_model_versions_file \
    en \
    --use-base-internationalization \
    --build-file-sub-identifiers-files \
    /tmp/pbxproj_partials/buildfile_subidentifiers/0 \
    /tmp/pbxproj_partials/buildfile_subidentifiers/1 \
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
		FF0000000000000000000003 /* /tmp/workspace */ = {
			isa = PBXGroup;
			children = (
				FF8A8BB7CD343AA2AD99B7D7 /* a */,
				FF0000000000000000000006 /* Bazel External Repositories */,
				FF0000000000000000000007 /* Bazel Generated Files */,
				FF0000000000000000000004 /* Products */,
				FF0000000000000000000005 /* Frameworks */,
			);
			path = /tmp/workspace;
			sourceTree = "<absolute>";
		};
		FF618557827D807616833360 /* a/project/file */ = {isa = PBXFileReference; path = file; sourceTree = "<group>"; };
		FFF68CE2ED8F1446235A4DB2 /* a/project/structure/resource/folder */ = {isa = PBXFileReference; lastKnownFileType = folder; path = folder; sourceTree = "<group>"; };
		FFB422F0ED47DD0C4ADD5CFA /* a/project/structure/resource */ = {
			isa = PBXGroup;
			children = (
				FFF68CE2ED8F1446235A4DB2 /* a/project/structure/resource/folder */,
			);
			path = resource;
			sourceTree = "<group>";
		};
		FF471380A7AFE2DA60BC3C9B /* a/project/structure */ = {
			isa = PBXGroup;
			children = (
				FFB422F0ED47DD0C4ADD5CFA /* a/project/structure/resource */,
			);
			path = structure;
			sourceTree = "<group>";
		};
		FF9F0CA95BD3964133377AB3 /* a/project */ = {
			isa = PBXGroup;
			children = (
				FF471380A7AFE2DA60BC3C9B /* a/project/structure */,
				FF618557827D807616833360 /* a/project/file */,
			);
			path = project;
			sourceTree = "<group>";
		};
		FF8A8BB7CD343AA2AD99B7D7 /* a */ = {
			isa = PBXGroup;
			children = (
				FF9F0CA95BD3964133377AB3 /* a/project */,
			);
			path = a;
			sourceTree = "<group>";
		};
		FF2D89561CA3C406C9CF606C /* bazel-out/generated/file */ = {isa = PBXFileReference; path = file; sourceTree = "<group>"; };
		FF6D171B1F90907BD3CC8646 /* bazel-out/generated */ = {
			isa = PBXGroup;
			children = (
				FF2D89561CA3C406C9CF606C /* bazel-out/generated/file */,
			);
			path = generated;
			sourceTree = "<group>";
		};
		FF0000000000000000000007 /* Bazel Generated Files */ = {
			isa = PBXGroup;
			children = (
				FF6D171B1F90907BD3CC8646 /* bazel-out/generated */,
			);
			name = "Bazel Generated Files";
			path = "bazel-out";
			sourceTree = SOURCE_ROOT;
		};
		FFCF7B42ADC95209BD08D946 /* external/repository/file */ = {isa = PBXFileReference; path = file; sourceTree = "<group>"; };
		FF350C2347512B944024D41B /* external/repository */ = {
			isa = PBXGroup;
			children = (
				FFCF7B42ADC95209BD08D946 /* external/repository/file */,
			);
			path = repository;
			sourceTree = "<group>";
		};
		FF0000000000000000000006 /* Bazel External Repositories */ = {
			isa = PBXGroup;
			children = (
				FF350C2347512B944024D41B /* external/repository */,
			);
			name = "Bazel External Repositories";
			path = ../../external;
			sourceTree = SOURCE_ROOT;
		};
		FF0000000000000000000004 /* Products */ = {
			isa = PBXGroup;
			children = (
				06005D29A3B70000000000FF /* App.app */,
				06002428EDCA0000000000FF /* tests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
	};
	rootObject = FF0000000000000000000001 /* Project object */;
}

```

### `resolved_repositories`

```
"." "/tmp/workspace" "./external/a/b" "/ex/a/b"

```
