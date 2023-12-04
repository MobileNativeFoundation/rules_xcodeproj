# `XCScheme`s generator

The `xcschemes` generator generates `.xcscheme` files for a project.

## Inputs

The generator accepts the following command-line arguments (see
[`GeneratorArguments.swift`](src/Generator/GeneratorArguments.swift) and
[`XCSchemes.swift`](src/XCSchemes.swift) for more
details):

- Positional `output-directory`
- Positional `scheme-management-output-path`
- Positional `autogeneration-mode`
- Positional `default-xcode-configuration`
- Positional `workspace`
- Positional `install-path`
- Positional `extension-point-identifiers-file`
- Positional `execution-actions-file`
- Positional `targets-args-env-file`
- Positional `custom-schemes-file`
- Positional `transitive-preview-targets-file`
- Option `--consolidation-maps <consoliation-map> ...`
- Optional option `--target-and-extension-hosts <target> <extension-host> ...`
- Flag `--colorize`

Here is an example invocation:

```shell
$ xcschemes \
    /tmp/pbxproj_partials/xcschemes \
    /tmp/pbxproj_partials/xcschememanagement.plist \
    auto \
    Debug \
    /tmp/workspace \
    some/project.xcodeproj \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_extension_point_identifiers \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/execution_actions_file \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/targets_args_env \
    bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/custom_schemes_file \
    --consolidation-maps \
    /tmp/pbxproj_partials/consolidation_maps/0 \
    /tmp/pbxproj_partials/consolidation_maps/1
```

## Output

Here is an example output:

### `generator.xcscheme`

```
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "9999"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "NO">
      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Initialize Bazel Build Output Groups File"
               scriptText = "mkdir -p &quot;${BUILD_MARKER_FILE%/*}&quot;&#10;touch &quot;$BUILD_MARKER_FILE&quot;&#10;">
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "0200222B2169000000000001"
                     BuildableName = "xcschemes"
                     BlueprintName = "xcschemes"
                     ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Prepare BazelDependencies"
               scriptText = "mkdir -p &quot;$PROJECT_DIR&quot;&#10;&#10;if [[ &quot;${ENABLE_ADDRESS_SANITIZER:-}&quot; == &quot;YES&quot; || \&#10;      &quot;${ENABLE_THREAD_SANITIZER:-}&quot; == &quot;YES&quot; || \&#10;      &quot;${ENABLE_UNDEFINED_BEHAVIOR_SANITIZER:-}&quot; == &quot;YES&quot; ]]&#10;then&#10;    # TODO: Support custom toolchains once clang.sh supports them&#10;    cd &quot;$INTERNAL_DIR&quot; || exit 1&#10;    ln -shfF &quot;$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib&quot; lib&#10;fi&#10;">
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "0200222B2169000000000001"
                     BuildableName = "xcschemes"
                     BlueprintName = "xcschemes"
                     ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
      </PreActions>
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "NO"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "NO"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "0200222B2169000000000001"
               BuildableName = "xcschemes"
               BlueprintName = "xcschemes"
               ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "030050899654000000000001"
               BuildableName = "PBXProjTests.xctest"
               BlueprintName = "PBXProjTests"
               ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "080032A25874000000000001"
               BuildableName = "XCSchemeTests.xctest"
               BlueprintName = "XCSchemeTests"
               ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "05002D1B3971000000000001"
               BuildableName = "xcschemes_tests.xctest"
               BlueprintName = "xcschemes_tests"
               ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      enableAddressSanitizer = "YES">
      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Update .lldbinit and copy dSYMs"
               scriptText = "&quot;$BAZEL_INTEGRATION_DIR/create_lldbinit.sh&quot;&#10;&quot;$BAZEL_INTEGRATION_DIR/copy_dsyms.sh&quot;&#10;">
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "030050899654000000000001"
                     BuildableName = "PBXProjTests.xctest"
                     BlueprintName = "PBXProjTests"
                     ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
      </PreActions>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "BUILD_WORKING_DIRECTORY"
            value = "$(BUILT_PRODUCTS_DIR)"
            isEnabled = "YES">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "BUILD_WORKSPACE_DIRECTORY"
            value = "$(BUILD_WORKSPACE_DIRECTORY)"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "030050899654000000000001"
               BuildableName = "PBXProjTests.xctest"
               BlueprintName = "PBXProjTests"
               ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
            </BuildableReference>
         </TestableReference>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "080032A25874000000000001"
               BuildableName = "XCSchemeTests.xctest"
               BlueprintName = "XCSchemeTests"
               ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
            </BuildableReference>
         </TestableReference>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "05002D1B3971000000000001"
               BuildableName = "xcschemes_tests.xctest"
               BlueprintName = "xcschemes_tests"
               ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      enableAddressSanitizer = "YES"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Update .lldbinit and copy dSYMs"
               scriptText = "&quot;$BAZEL_INTEGRATION_DIR/create_lldbinit.sh&quot;&#10;&quot;$BAZEL_INTEGRATION_DIR/copy_dsyms.sh&quot;&#10;">
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "0200222B2169000000000001"
                     BuildableName = "xcschemes"
                     BlueprintName = "xcschemes"
                     ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
      </PreActions>
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "0200222B2169000000000001"
            BuildableName = "xcschemes"
            BlueprintName = "xcschemes"
            ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <CommandLineArguments>
         <CommandLineArgument
            argument = "/tmp/pbxproj_partials/xcschemes"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "/tmp/pbxproj_partials/xcschememanagement.plist"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "auto"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "Debug"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "/tmp/workspace"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "some/project.xcodeproj"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_extension_point_identifiers"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/execution_actions_file"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/targets_args_env"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/custom_schemes_file"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "--consolidation-maps"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "/tmp/pbxproj_partials/consolidation_maps/0"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "/tmp/pbxproj_partials/consolidation_maps/1"
            isEnabled = "YES">
         </CommandLineArgument>
      </CommandLineArguments>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "BUILD_WORKING_DIRECTORY"
            value = "$(BUILT_PRODUCTS_DIR)"
            isEnabled = "YES">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "BUILD_WORKSPACE_DIRECTORY"
            value = "$(BUILD_WORKSPACE_DIRECTORY)"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Update .lldbinit and copy dSYMs"
               scriptText = "&quot;$BAZEL_INTEGRATION_DIR/create_lldbinit.sh&quot;&#10;&quot;$BAZEL_INTEGRATION_DIR/copy_dsyms.sh&quot;&#10;">
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "0200222B2169000000000001"
                     BuildableName = "xcschemes"
                     BlueprintName = "xcschemes"
                     ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
      </PreActions>
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "0200222B2169000000000001"
            BuildableName = "xcschemes"
            BlueprintName = "xcschemes"
            ReferencedContainer = "container:/Users/brentley/Developer/rules_xcodeproj/tools/tools.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <CommandLineArguments>
         <CommandLineArgument
            argument = "/tmp/pbxproj_partials/xcschemes"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "/tmp/pbxproj_partials/xcschememanagement.plist"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "auto"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "Debug"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "/tmp/workspace"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "some/project.xcodeproj"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_extension_point_identifiers"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/execution_actions_file"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/targets_args_env"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "bazel-output-base/rules_xcodeproj.noindex/build_output_base/execroot/_main/bazel-out/darwin_arm64-dbg/bin/external/_main~internal~rules_xcodeproj_generated/generator/tools/xcodeproj/xcodeproj_pbxproj_partials/custom_schemes_file"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "--consolidation-maps"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "/tmp/pbxproj_partials/consolidation_maps/0"
            isEnabled = "YES">
         </CommandLineArgument>
         <CommandLineArgument
            argument = "/tmp/pbxproj_partials/consolidation_maps/1"
            isEnabled = "YES">
         </CommandLineArgument>
      </CommandLineArguments>
      <EnvironmentVariables>
         <EnvironmentVariable
            key = "BUILD_WORKING_DIRECTORY"
            value = "$(BUILT_PRODUCTS_DIR)"
            isEnabled = "YES">
         </EnvironmentVariable>
         <EnvironmentVariable
            key = "BUILD_WORKSPACE_DIRECTORY"
            value = "$(BUILD_WORKSPACE_DIRECTORY)"
            isEnabled = "YES">
         </EnvironmentVariable>
      </EnvironmentVariables>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Debug"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>

```

### `xcschememanagement.plist`

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SchemeUserState</key>
	<dict>
		<key>files_and_groups.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>0</integer>
		</dict>
		<key>import_indexstores.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>1</integer>
		</dict>
		<key>pbxnativetargets.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>2</integer>
		</dict>
		<key>pbxproj_prefix.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>3</integer>
		</dict>
		<key>pbxtargetdependencies.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>4</integer>
		</dict>
		<key>swift_debug_settings.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>5</integer>
		</dict>
		<key>swiftc_stub.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>6</integer>
		</dict>
		<key>target_build_settings.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>7</integer>
		</dict>
		<key>xcschemes.xcscheme_^#shared#^_</key>
		<dict>
			<key>isShown</key>
			<true/>
			<key>orderHint</key>
			<integer>8</integer>
		</dict>
	</dict>
</dict>
</plist>

```
