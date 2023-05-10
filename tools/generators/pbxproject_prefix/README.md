# `PBXProject` prefix `PBXProj` partial generator

The `pbxproject_prefix` generator creates a `PBXProj` partial containing the
start (i.e. prefix) of the `PBXProject` element.

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`PBXProjectPrefix.swift`](src/PBXProjectPrefix.swift) for more details):

- Positional `output-path`
- Positional `workspace`
- Positional `execution-root-file`
- Positional `minimum-xcode-version`
- Optional option `--development-region <development-region>`
- Optional option `--organization-name <organization-name>`
- Flag `--colorize`

Here is an example invocation:

```shell
$ pbxproject_prefix \
    /tmp/pbxproj_partials/pbxproject_prefix \
    /tmp/workspace \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/generators/xcodeproj/xcodeproj_execution_root_file \
    14.0 \
    --development-region enGB \
    --organization-name MobileNativeFoundation
```

## Output

Here is an example output:

```
		000000000000000000000001 /* Project object */ = {
			isa = PBXProject;
			buildConfigurationList = 000000000000000000000004 /* Build configuration list for PBXProject */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = enGB;
			hasScannedForEncodings = 0;
			mainGroup = 000000000000000000000002 /* /tmp/workspace */;
			productRefGroup = 000000000000000000000003 /* Products */;
			projectDirPath = /tmp/workspace/bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main;
			projectRoot = "";
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 9999;
				LastUpgradeCheck = 9999;
				ORGANIZATIONNAME = MobileNativeFoundation;
```
