# `project.pbxproj` generator

The `project_pbxproj` generator assembles the `project.pbxproj` file from the
`PBXProj` partials created by the other generators, in the layout that Xcode
writes, so Xcode doesn't need to rewrite the file when it next saves the
project.

The partials are concatenated, and then the objects in `objects = { ... }` are
grouped by `isa` into `/* Begin <isa> section */` ... `/* End <isa> section */`
blocks. Sections are sorted by `isa`, and objects within a section by
identifier. Objects, and everything outside of `objects`, are copied as is.

Each object needs to start on a line indented with exactly two tabs, and either
be completely on that line (`\t\t<id> /* <comment> */ = {isa = <isa>; ...};`),
or have `isa` as its first attribute on the next line (`\t\t\tisa = <isa>;`)
and end at a line that is exactly `\t\t};`. Otherwise generation fails.

## Inputs

The generator accepts the following command-line arguments:

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
