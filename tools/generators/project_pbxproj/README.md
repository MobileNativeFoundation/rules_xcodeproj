# `project.pbxproj` generator

The `project_pbxproj` generator assembles the `project.pbxproj` file from the
`PBXProj` partials created by the other generators, in the same layout that
Xcode writes. This means Xcode doesn't need to rewrite the file when it next
saves the project.

The partials are concatenated, and then:

- Everything up to and including the `objects = {` line, and everything from
  the line closing `objects`, is copied as is
- Objects are grouped by their `isa` into `/* Begin <isa> section */` ...
  `/* End <isa> section */` blocks, which are sorted by `isa`
- Objects within a section are sorted by identifier
- Each object is copied as is, as the generators write attributes in the order
  Xcode does

Objects need to be formatted the way Xcode formats them. Each one starts on a
line indented with exactly two tabs, and either:

- Is completely on that line, ending with `};`, with `isa` as its first
  attribute (`\t\t<id> /* <comment> */ = {isa = <isa>; ...};`)
- Continues on lines indented with at least three tabs, with `isa` as its first
  attribute (`\t\t\tisa = <isa>;`), until a line that is exactly `\t\t};`

Malformed partials (no `objects = {` line, an object without an `isa`, or an
object that isn't terminated) result in an error.

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`ProjectPBXProj.swift`](src/ProjectPBXProj.swift) for more details):

- Positional `output-path`
- Positional list `<partials> ...`, in the order they need to be concatenated
- Flag `--colorize`

Here is an example invocation:

```shell
$ project_pbxproj \
    /tmp/pbxproj_partials/project.pbxproj \
    /tmp/pbxproj_partials/pbxproj_prefix \
    /tmp/pbxproj_partials/pbxnativetargets/0 \
    /tmp/pbxproj_partials/pbxnativetargets/1 \
    /tmp/pbxproj_partials/pbxtargetdependencies \
    /tmp/pbxproj_partials/files_and_groups
```

## Output

Here is an excerpt of an example output:

```
	objects = {

/* Begin PBXAggregateTarget section */
		FF0100000000000000000001 /* BazelDependencies */ = {
			isa = PBXAggregateTarget;
			...
		};
/* End PBXAggregateTarget section */

/* Begin PBXBuildFile section */
		0100000000000000000000B1 /* a.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0100000000000000000000F1 /* a.swift */; };
		0100000000000000000000B2 /* b.swift in Sources */ = {isa = PBXBuildFile; fileRef = 0100000000000000000000F2 /* b.swift */; };
/* End PBXBuildFile section */
...
/* End XCConfigurationList section */
	};
	rootObject = FF0000000000000000000001 /* Project object */;
}
```
