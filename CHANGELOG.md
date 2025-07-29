# Changelog

This is a human-friendly changelog in a [keepachangelog.com](https://keepachangelog.com) style format.
Because this changelog is for end-user consumption of meaningful changes,
only a summary of a release’s changes is described.
This means every commit is not necessarily mentioned,
and internal refactors or code cleanups are omitted unless they’re particularly notable.

<!--
BEGIN_UNRELEASED_TEMPLATE

<a id="unreleased"></a>
## [Unreleased]

[Unreleased]: https://github.com/MobileNativeFoundation/rules_xcodeproj/compare/%PREVIOUS_TAG%...HEAD

### ⚠️ Breaking changes ⚠️

* TBD

### New

* TBD

### Adjusted

* TBD

### Fixed

* TBD

### Ruleset Development Changes

* TBD

END_UNRELEASED_TEMPLATE
-->

<a id="unreleased"></a>
## [Unreleased]

[Unreleased]: https://github.com/MobileNativeFoundation/rules_xcodeproj/compare/3.1.1...HEAD

### ⚠️ Breaking changes ⚠️

* TBD

### New

* TBD

### Adjusted

* TBD

### Fixed

* TBD

### Ruleset Development Changes

* TBD

<a id="3.1.1"></a>
## [3.1.1] - 2025-07-29

[3.1.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/3.1.1

### Fixed

* Fixed improper capitalization of build diagnostics: [#3217](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3217)

<a id="3.1.0"></a>
## [3.1.0] - 2025-07-25

[3.1.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/3.1.0

### Adjusted

* Added `SIGINT` handler for `process_bazel_build_log.py`: [#3200](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3200)
* We now use `--@rules_swift//swift:copt` instead of `--swiftcopt`: [#3206](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3206)
* Removed `--experimental_action_cache_store_output_metadata`: [#3207](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3207)
* Optimized out an extra regular expression substitution: [#3208](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3208)

### Fixed

* Fixed build log parsing for 'fatal error:' diagnostics: [#3204](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3204)
* Fixed incorrect sha256 for **rules_swift**: [#3210](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3210)
* Added `Testing.framework` to testing frameworks: [#3211](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3211)
* Added support for new convention for WMO module deps artifacts naming in Xcode 26 beta 3: [#3212](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3212)
* Fixed Metal toolchains in Xcode 26 betas: [#3213](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3213)

<a id="3.0.0"></a>
## [3.0.0] - 2025-06-13

[3.0.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/3.0.0

### ⚠️ Breaking changes ⚠️

* Removed the legacy generator mode and other related deprecated things: [#3192](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3192) and [#3193](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3193)
* **rules_swift** 3.0+ is required: [#3187](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3187)

### New

* Public APIs are now in their own files, deprecating `defs.bzl`: [#3194](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3194)

### Adjusted

* Added support for **rules_swift** 3.0: [#3187](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3187)

### Fixed

* Fixed `_allow_remote_write_target_build_settings` typo: [#3191](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3191)

### Ruleset Development Changes

* Added rules_shell dev dependency: [#3196](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3196)
* Added protobuf dep to `examples/integration`: [#3197](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3197)
* We set `--incompatible_use_default_test_toolchain=no` for now: [#3199](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3199)

<a id="2.12.0"></a>
## [2.12.0] - 2025-05-07

[2.12.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.12.0

### Adjusted

* We now use BCR for `kylef/PathKit` and `tuist/xcodeproj` deps: [#3153](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3153)
* We now skip targets without `compiles` output group in `compile_only` aspect: [#3172](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3172)

### Fixed

* Fixed more `rsync` permission issues: [#3175](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3175)
* Fixed argument length error for `WriteSwiftDebugSettings`: [#3173](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3173)
* Adopted latest `index-import version` (v6.1.0.1) to fix issue with `libzstd.1.dylib`: [#3174](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3174)

<a id="2.11.2"></a>
## [2.11.2] - 2025-04-09

[2.11.2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.11.2

### Fixed

* Fixed `index-import` to work on all Xcode 16.x versions: [#3162](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3162)

<a id="2.11.1"></a>
## [2.11.1] - 2025-04-01

[2.11.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.11.1

### New

* Added `compile_only` aspect: [#3156](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3156)

### Fixed

* Fixed `rsync` on macOS 15.4: [#3157](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3157)
* Fixed `comm` on macOS 15.4: [#3161](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3161)

<a id="2.11.0"></a>
## [2.11.0] - 2025-03-25

[2.11.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.11.0

### Adjusted

* We now default `LANG` to `en_US.UTF-8` in project generation: [#3143](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3143)
* Indexstore `.filelist` creation has been simplified: [#3144](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3144)
* `WriteTargetBuildSettings` can now optionally use remote cache or RBE: [#3149](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3149)
* We now use `--action_env=TOOLCHAINS=` instead of `--define=SWIFT_CUSTOM_TOOLCHAIN=`: [#3123](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3123)
* Changed instances of `--experimental_remote_download_regex` to `--remote_download_regex`: [#3125](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3125)

### Fixed

* We now use `md5sum` when not on macOS: [#3145](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3145)
* `xcode-select` or `DEVELOPER_DIR` are no longer required to generate a project: [#3147](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3147)
* Fixed `incremental_installer.sh` when running on Linux: [#3148](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3148)
* `swift_compiler_plugin` sources are now added to the generated project: [#3142](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3142)
* Removed duplicate post/pre actions: [#3122](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3122)

<a id="2.10.0"></a>
## [2.10.0] - 2024-12-16

[2.10.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.10.0

### ⚠️ Breaking changes ⚠️

* “Make” variables are now expanded values in the `env` dictionary on test rules: [#3088](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3088)
* Upgraded rules_apple to 3.16.1: [#3114](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3114)
  * Drops support for Bazel 6

### New

* Added ExtensionKit support: [#3109](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3109)

### Fixed

* Fixed support for Bazel 8 and 9: [#3117](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3117)

### Ruleset Development Changes

* Upgraded to Bazel 8.0.0: [#3119](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3119)

<a id="2.9.2"></a>
## [2.9.2] - 2024-11-18

[2.9.2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.9.2

### Fixed

* Fixed parsing of custom scheme test options: [#3110](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3110)

<a id="2.9.1"></a>
## [2.9.1]

[2.9.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.9.1 - 2024-11-14

### Fixed

* Fixed when `xcschemes.autogeneration_config.test` is not set: [#3108](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3108)

<a id="2.9.0"></a>
## [2.9.0] - 2024-11-13

[2.9.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.9.0

### New

* Added support for `App Language` and `App Region` scheme test action options: [#3105](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3105)

### Fixed

* Fixed handling of `mixed_language_library` when both targets are unfocused: [#3104](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3104)

<a id="2.8.1"></a>
## [2.8.1] - 2024-10-29

[2.8.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.8.1

### Fixed

* Fixed missing BUILD files in Project navigator: [#3102](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3102)

<a id="2.8.0"></a>
## [2.8.0] - 2024-10-28

[2.8.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.8.0

### New

* Added thread checkers to `xcscheme.diagnostics`: [#3096](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3096)

### Adjusted

* Structured resources are now represented as files instead of folders in Xcode: [#3098](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3098) and [#3100](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3100)

### Fixed

* Fixed "Generate Bazel Dependencies" target name typo Fix typo: [#3091](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3091)
* Fixed handling of `apple_precompiled_resource_bundle` and similar rules: [#3097](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3097) and [#3099](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3099)

<a id="2.7.0"></a>
## [2.7.0] - 2024-08-21

[2.7.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.7.0

### ⚠️ Breaking changes ⚠️

* Environment variables are now filtered when building with Bazel: [#3075](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3075), [#3077](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3077), and [#3081](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3081)
  * This shouldn't break anyone, but if it does, `xcodeproj.bazel_env` is the suggested fix
* Only the debug settings from the most-downstream Swift targets are used: [#3073](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3073)
  * For this to work best, the library target for a top-level target should be a `swift_library`, `mixed_language_library`, or equivalent. Using a non-Swift library can result in now-broken lldb debugging

### Adjusted

* Aligned the various `--experimental_remote_download_regex` flags: [#3076](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3076)
* Less work is performed when not importing Index Build indexstores: [#3078](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3078)
* The same output base is now used for Xcode Build and Index Build: [#3074](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3074) and [#3080](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3080)

### Fixed

* Fixed target merging involving source-less library targets: [#3079](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3079)
* Fixed unfocused framework target input files filtering: [#3085](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3085)
* Fixed top-level targets merging with `mixed_language_library`: [#3082](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3082)
* `-const-gather-protocols-file` is now skipped when calculating `SWIFT_OTHER_FLAGS`: [#3084](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3084)

<a id="2.6.1"></a>
## [2.6.1] - 2024-08-13

[2.6.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.6.1

### Fixed

* Fixed unfocused top-level targets: [#3072](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3072)

<a id="2.6.0"></a>
## [2.6.0] - 2024-08-12

[2.6.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.6.0

### New

* Added support for **rules_swift**’s `mixed_language_library`: [#3063](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3063) and [#3069](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3069)

### Adjusted

* Generated files are now co-located with package source files: [#3049](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3049) and [#3071](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3071)
* Headers are now included in `--remote_download_regex`: [#3061](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3061) and [#3062](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3062)

<a id="2.5.2"></a>
## [2.5.2] - 2024-07-17

[2.5.2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.5.2

### Fixed

* Fixed `swiftc` version invocation used in Xcode 16 Beta 3: [#3058](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3058)

<a id="2.5.1"></a>
## [2.5.1] - 2024-07-09

[2.5.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.5.1

### Fixed

* Fixed permissions on renamed `ld` and `libtool` scripts: [#3053](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3053)

<a id="2.5.0"></a>
## [2.5.0] - 2024-07-09

[2.5.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.5.0

### Adjusted

* Added support for rules_swift 2.0’s `swift_test`: [#3051](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3051)
* Declared that we support rules_swift compatibility level 2: [#3052](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3052)
* Renamed `ld.sh` to `ld`: [#3041](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3041)
* Renamed `libtool.sh` to `libtool`: [#3043](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3043)
* We now set `ENABLE_DEBUG_DYLIB = NO` until we properly support Xcode 16: [#3042](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3042)

### Fixed

* Fixed incremental project generation swift debugging: [#3046](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3046)

<a id="2.4.0"></a>
## [2.4.0] - 2024-05-29

[2.4.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.4.0

### New

* Added [`xcschemes.autogeneration_config`](/docs/bazel.md#xcschemesautogeneration_config): [#3027](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3027)
* Added [`xcodeproj.import_index_build_indexstores`](/docs/bazel.md#xcodeproj-import_index_build_indexstores): [#3034](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3034)

### Fixed

* Fixed mistranslation of external sources: [#3028](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3028)

<a id="2.3.1"></a>
## [2.3.1] - 2024-05-09

[2.3.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.3.1

### Fixed

* Fixed build when `IDEBuildingContinueBuildingAfterErrors` has never been set [#3024](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3024)

<a id="2.3.0"></a>
## [2.3.0] - 2024-05-09

[2.3.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.3.0

### New

* The "Continue building after errors" setting in Xcode is now respected: [#3020](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3020)

### Adjusted

* Only declared input headers are now included in the project navigator: [#3015](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3015), [#3016](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3016), and [#3017](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3017)

### Fixed

* Fixed `associated_extra_files` when multiple targets own the same file: [#3023](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3023)

<a id="2.2.0"></a>
## [2.2.0] - 2024-04-15

[2.2.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.2.0

### Fixed

* Fixed handling of multiple `associated_extra_files` per target in incremental generation mode: [#3011](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3011)
* Target dependencies are now adjusted for transitive Xcode Preview targets instead of schemes: [#3005](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3005)
* Expanded `SUPPORTED_PLATFORMS` for application extensions: [#3012](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3012)

<a id="2.1.1"></a>
## [2.1.1] - 2024-04-09

[2.1.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.1.1

### Fixed

* Upgraded WORKSPACE and dev **rules_apple**: [#3002](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3002)
* Fixed missing `BAZEL_PACKAGE_BIN_DIR` for non-Swift targets in incremental generation mode: [#3004](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3004)

### Ruleset Development Changes

* Upgraded dev **rules_swift**: [#3003](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3003)

<a id="2.1.0"></a>
## [2.1.0] - 2024-04-05

[2.1.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.1.0

### Adjusted

* Added `module.bazel_compatibility` to reflect our minimum supported Bazel version: [#2995](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2995)
* Upgraded WORKSPACE version of **rules_swift** and **rules_apple**: [#2996](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2996)

### Fixed

* Fixed `extension_host` error when using `launch_path`: [#2992](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2992)
* Test hosts are no longer included in schemes when `adjust_schemes_for_swiftui_previews = True`: [#2991](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2991)
* The correct action (e.g. Test or Run) is now set for transitive Xcode Preview dependencies: [#2993](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2993)

### Ruleset Development Changes

* Upgraded dev version of **rules_swift** and **rules_apple**: [#2996](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2996)

<a id="2.0.0"></a>
## [2.0.0] - 2024-04-03

[2.0.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/2.0.0

### ⚠️ Breaking changes ⚠️

* Changed the default value for [`xcodeproj.generation_mode`](docs/bazel.md#xcodeproj-generation_mode) from `legacy` to `incremental`: [#2986](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2986)
* Removed some deprecated attributes: [#2988](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2988)

### New

* Environment variables are now resolved in `bazel_env`: [#2983](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2983)
* `additional_*_inputs` are now collected as extra files in incremental generation mode: [#2972](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2972)
* `swiftc_inputs` are now collected as extra files in incremental generation mode: [#2971](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2971)

### Adjusted

* Reduced work that incremental generation mode installer does for generated directories: [#2956](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2956) & [#2965](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2965)
* The adjusted `Info.plist` is now used for `extension_infoplists` in incremental generation mode: [#2966](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2966)
* `exec` configuration targets are no longer processed in incremental generation mode: [#2968](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2968)

### Fixed

* Indentation related `project_options` are now applied in incremental generation mode: [#2959](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2959)
* Uncategorized files are no longer collected for unfocused targets in incremental generation mode: [#2960](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2960) & [#2982](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2982)
* Uncategorized files are no longer collected for source-less library targets in incremental generation mode: [#2969](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2969)
* The swift generated header is now excluded from the project in incremental generation mode: [#2961](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2961)
* `codesign_inputs` are now collected as extra files in incremental generation mode: [#2970](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2970)
* Fixed `build_mode` to be set `bazel` when passed in `None` or `""`: [#2987](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2987)

### Ruleset Development Changes

* Locked down distribution to a specific Xcode version: [#2954](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2954)

<a id="1.18.0"></a>
## [1.18.0] - 2024-03-12

[1.18.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.18.0

### New

* Added support for visionOS: [#2922](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2922)
* Added Ruby file type extension for `Podspec` files: [#2932](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2932)
* Added `literal_string` argument to `xcschemes.arg`: [#2938](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2938)

### Adjusted

* Upgraded WORKSPACE version of rules_swift to 1.16.0: [#2927](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2927)
* `--experimental_remote_download_regex` is no longer set by default with the command-line API: [#2930](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2930)
* Timing output from `calculate_output_groups.py` is now flushed immediately: [#2931](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2931)
* We now work around when `bazelisk` is called recursively during project generation: [#2929](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2929)
* Made `xcschemes.top_level_anchor_target` work with `*_build_test` targets: [#2945](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2945) & [#2949](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2949)

### Fixed

* Fixed Xcode 15.3 LLDB debugging: [#2947](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2947)
* Fixed an error when using an empty or `None` `xcschemes.env` value: [#2935](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2935)
* Fixed stale tests with test hosts when deploying to simulator: [#2936](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2936)
* `explicitFileType` is now correctly set for `.bazel` and `.bzl` extensions in incremental generation mode: [#2928](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2928)
* Fixed performance of `associated_extra_files` with incremental generation mode: [#2944](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2944) & [#2948](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2948)

### Ruleset Development Changes

* Upgrade dev version of rules_swift to 1.16.0: [#2927](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2927)

<a id="1.17.0"></a>
## [1.17.0] - 2024-02-27

[1.17.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.17.0

### New

* Added support for the new `swift_proto_library` rule: [#2832](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2832)

### Adjusted

* Added support for argument lists in `swiftc_stub`: [#2907](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2907)
* We now log when the Bazel build is starting: [#2895](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2895)
* Upgraded WORKSPACE versions of rules_apple: [#2912](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2912)
* Removed incremental generation mode extra `CODE_SIGNING_ALLOWED` logic: [#2921](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2921)

### Fixed

* Fixed duplicate `same_as_run` launch target pre/post actions: [#2892](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2892)
* Fixed frozen list issue with incremental generation: [#2894](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2894)
* Fixed more code signing issues of UI tests with incremental generation: [#2919](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2919)
* Fixed processing of folder-type uncategorized resources with incremental generation: [#2918](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2918)
* Fixed tree artifact `File` handling with incremental generation: [#2905](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2905)
* Fixed tvOS Xcode preview framework code signing with incremental generation: [#2920](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2920)
* `xcschemes` no longer errors when listing a merged target in `library_targets`: [#2897](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2897)

### Ruleset Development Changes

* Upgraded development apple_support and rules_apple versions: [#2912](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2912)

<a id="1.16.0"></a>
## [1.16.0] - 2024-01-29

[1.16.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.16.0

### New

* Added support for pre/post actions with `launch_path`: [#2866](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2866)

### Adjusted

* Added a failure when `product.original_basename` isn’t set: [#2879](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2879)
* Improved performance of the `files_and_groups` incremental generator: [#2870](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2870)
* Upgraded `xcodeproj_rules_dependencies` rules_apple, rules_swift, and bazel_features: [#2882](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2882)
* Upgraded bazel_features to 1.3.0: [#2883](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2883)
* Removed bitcode support: [#2887](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2887)

### Fixed

* Fixed macro expansion for test schemes without launch targets: [#2868](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2868)
* Fixed some args and env setting in incremental generation schemes: [#2869](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2869)
* Fixed SwiftUI Previews link command-line length issue with incremental generation mode: [#2878](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2878)
* Fixed Bazel 6 handling of `libSwiftProtobuf.a`: [#2888](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2888)
* Fixed the command-line API to support all Bazel commands via the `common` pseudo-command: [#2889](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2889)

### Ruleset Development Changes

* Upgraded dev versions of rules_apple and rules_swift: [#2884](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2884) and [#2886](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2886)

<a id="1.15.0"></a>
## [1.15.0] - 2024-01-08

[1.15.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.15.0

### New

* `cmake` sources are now included in the Project navigator: [#2847](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2847)

### Adjusted

* The default `--experimental_remote_download_regex` flag set by **rules_xcodeproj** has been expanded to explicitly list file types needed for indexing: [#2859](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2859)
  * Incremental generation mode has been adjusted to not manually track generated files, resulting in lower CPU and memory usage
  * The targets for a scheme (e.g. `.app`, `.xctest`, `.a`) are now built in Index Build, similar to how Xcode does it
  * This should improve indexing of more complicated setups (e.g. ones that use VFS overlays or hmap files)
* Added `--experimental_use_cpp_compile_action_args_params_file` to baseline `xcodeproj.bazelrc`: [#2850](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2850)
  * Fixes a long command-line issue in incremental generation mode

### Fixed

* Fixed `build_targets` in `xcschemes` to accept string labels: [#2864](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2864)
* Fixed folder-type files (e.g. `.xcassets`) in incremental generation mode: [#2841](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2841)
* Fixed generated input source file error in incremental generation mode: [#2851](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2851)
* Fixed simulator UI test debugging in incremental generation mode: [#2849](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2849)
* Fixed a potential hang in `import_indexstores`: [#2858](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2858)

<a id="1.14.2"></a>
## [1.14.2] - 2023-12-19

[1.14.2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.14.2

### Fixed

* Fix another incremental installer issue: [#2826](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2826)

<a id="1.14.1"></a>
## [1.14.1] - 2023-12-19

[1.14.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.14.1

### Fixed

* Fixed incremental installer: [#2825](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2825)

<a id="1.14.0"></a>
## [1.14.0] - 2023-12-19

[1.14.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.14.0

### New

* Added a new incremental generation mode
  * Incremental generation mode is a new way for **rules_xcodeproj** to generate your project. Unlike the Build Mode (BwB or BwX), this should only really affect the process by which **rules_xcodeproj** takes to generate the project, not how the project itself behaves (with some small caveats). Here are some of the benefits of using incremental generation mode over the current (a.k.a `"legacy"`) generation mode:
    * _Much_ faster generation. Numbers from a large example project:
        * Clean
            * Analysis: **12% faster** (62s vs 71s)
            * Execution: **41% faster** (72s vs 123s)
        * Minimal incremental (add file to a top-level target)
            * Analysis: **36% faster** (13s vs 21s)
            * Execution: **93% faster** (8.5s vs 123s)
    * Lower Starlark memory usage (about 33% lower)
    * Improved target consolidation and target merging
        * Some targets can now consolidate better
        * Libraries can merge into multiple top-level targets
        * Mixed-language targets merge better
    * Improved indexing
        * All Swift compiler flags are now in the project, working around more SourceKit issues
    * Improved debugging
    * Improved handling of extra files (mainly around target focusing)
    * Improved Xcode Previews support
    * For maintainers, vastly improved maintainability (docs, tests, code structure, etc.)
  * This is currently opt in
    * Set [`xcodeproj.generation_mode`](docs/bazel.md#xcodeproj-generation_mode) to `"incremental"` to try it out
    * Use [`xcodeproj.xcschemes`](docs/bazel.md#custom-xcode-schemes-incremental-generation-mode), instead of `xcodeproj.schemes`, if you define custom schemes
    * **Note:** Only BwB mode is supported
* Added a Bzlmod dependency on `rules_python` `0.27.1`: [#2793](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2793)

### Adjusted

* Added recognition of additional `deps` attributes for rules_ios bundle rules: [#2750](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2750)
* Archived bundles are now extracted with Bazel instead of in `copy_outputs.sh`: [#2779](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2779)
* `cc_common.merge_cc_infos` is now only called if needed: [#2762](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2762)
* Disabled the `GenerateTAPI` Xcode action: [#2724](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2724)
* Improved handling of source-less library targets: [#2714](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2714)
* Optimized some Starlark CPU usage: [#2760](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2760)
* Optimized some Starlark retained memory usage: [#2769](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2769) and [#2777](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2777)
* Upgraded bazel_features to 1.1.1: [#2718](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2718)
* Upgraded apple_support, rules_apple, and rules_swift in `WORKSPACE` macro: [#2824](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2824)
* Removed `--collect_specs` support: [#2803](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2803)
* Removed `DEPLOYMENT_LOCATION` hack when using BwB mode: [#2790](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2790)

### Ruleset Development Changes

* Upgraded rules_apple related dev dependencies: [#2728](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2728)
* Upgraded dev version of skylib to 1.5.0: [#2729](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2729)

<a id="1.13.0"></a>
## [1.13.0] - 2023-10-30

[1.13.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.13.0

### Adjusted

* Moved `import_indexstores.sh` early exit to before kill: [#2670](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2670)
* Added target label to `xcodeproj` macro warnings and errors: [#2673](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2673)
* Converted `import_indexstores.sh` into a Swift binary: [#2671](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2671)
* `indexstores` are now included as inputs to `indexstore_filelist`: [#2681](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2681)
* Improved error message when `XCBBuildService` gets stuck on stale data: [#2688](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2688)
* Moved `calculate_output_groups.py` JSON parsing error reporting: [#2687](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2687)
* Made the launchable target error more detailed: [#2689](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2689)

### Fixed

* Fixed object path in Index Build imported unit files: [#2669](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2669)
* Made mutable copy of extensions when processing top-level target: [#2698](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2698)
* Non-Swift library targets now compile their code when building their scheme in Xcode: [#2699](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2699)
* We no longer delete `.xcodeproj/xcuserdata`: [#2700](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2700)

<a id="1.12.1"></a>
## [1.12.1] - 2023-10-04

[1.12.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.12.1

### Fixed

* Fixed framework Xcode previews: [#2663](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2663)

<a id="1.12.0"></a>
## [1.12.0] - 2023-10-04

[1.12.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.12.0

### Adjusted

* Upgraded `xcodeproj_rules_dependencies` rules_swift and rules_apple: [#2617](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2617)
* Tests now sort after library targets in schemes: [#2616](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2616)
* We no longer set `dwarf-with-dsym` in an additional location: [#2643](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2643)
* We no longer copy over frameworks in BwB mode: [#2644](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2644)
* Xcode target names using label form now favor shorthand form: [#2649](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2649)

### Fixed

* Fixed hanging `calculate_output_groups.py`: [#2660](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2660)

### Ruleset Development Changes

* Changed `examples` to use release archive: [#2614](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2614)
* Upgraded dev apple_support, rules_swift, and rules_apple: [#2622](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2622)
* Upgraded swift-argument-parser to 1.2.3: [#2632](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2632)
* Added `AppleLipo` to `--modify_execution_info`: [#2657](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2657)

<a id="1.11.0"></a>
## [1.11.0] - 2023-09-20

[1.11.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.11.0

### New

* Added the [`xcodeproj.target_name_mode`](docs/bazel.md#xcodeproj-target_name_mode) attribute: [#2590](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2590)

### Adjusted

* Removed fallback output group calculation: [#2541](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2541)
* Upgraded `xcodeproj_rules_dependencies` rules_apple to 2.5.0: [#2560](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2560)
* Upgraded `xcodeproj_rules_dependencies` rules_swift to 1.11.0: [#2561](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2561)
* `ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS = NO` is now set in BwB mode: [#2569](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2569)
* Bazel generated `.objlist` files are now prevented from in the project: [#2570](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2570)
* Bazel sandboxing is now disabled by default: [#2606](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2606)

### Fixed

* All transitive swiftmodules are now included in the `bc` output group when needed: [#2571](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2571)
* Fixed issues when using `--incompatible_fail_on_unknown_attributes`: [#2573](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2573) and [#2579](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2579)
* Fixed using `sync` with command-line API: [#2585](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2585)
* Fixed default of `ENABLE_USER_SCRIPT_SANDBOXING` for Xcode 15: [#2591](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2591)
* Fixed processed build log paths: [#2599](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2599)
* Fixed nondeterministic product file identifier: [#2602](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2602)
* dSYMs are no longer generated by Xcode in BwB mode: [#2605](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2605)

### Ruleset Development Changes

* Upgraded apple_support to 1.9.0: [#2553](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2553)
* `platform_mappings` are now used everywhere: [#2555](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2555) and [#2609](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2609)
* Upgraded development versions of rules_apple and rules_swift: [#2562](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2562)
* Dropped Bazel 5 dev files and cleaned up `platform_mappings` handling: [#2565](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2565)
* Removed `WORKSPACE` support for development: [#2566](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2566)
* Made `platform_mappings` bijective: [#2588](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2588)
* Bazel 6.4.0rc1 is now used for development: [#2608](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2608)
* The BLAKE3 digest function is now used for development: [#2611](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2611)

<a id="1.10.1"></a>
## [1.10.1] - 2023-09-06

[1.10.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.10.1

### Adjusted

* Removed generated `.proto.bin` files from target's `Compile Sources`: [#2538](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2538)
* Specified path to `sort`: [#2540](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2540)
* Reduced macOS requirement for legacy generator to 12.0: [#2545](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2545)
* Changed sorting of build action in schemes: [#2546](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2546)

<a id="1.10.0"></a>
## [1.10.0] - 2023-08-31

[1.10.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.10.0

### ⚠️ Breaking Changes ⚠️

* Added a dependency on `bazel_features`: [#2490](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2490)
  * If you don't use Bzlmod (i.e. use a `WORKSPACE` file), see the updated snippet at the end of the release notes.

### New

* Added initial support for `swift_proto_library` and `swift_grpc_library`: [#2484](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2484) and [#2515](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2515)
* Added support for `codesign_inputs` and improved support for `codesignopts`: [#2535](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2535)

### Adjusted

* Some intermediate params files are no longer unnecessarily created: [#2468](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2468) and [#2469](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2469)
* Generated `.swift` files are now downloaded when using BwtB: [#2473](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2473)
* Improved target merging: [#2471](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2471), [#2482](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2482), [#2487](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2487)
* Starlark performance improvements: [#2518](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2518), [#2519](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2519), [#2536](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2536), and [#2537](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2537)
* `CLANG_ENABLE_MODULES` is no longer set: [#2528](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2528)
* Removed support for WatchKit 1: [#2527](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2527)
* We now count `precompiled_apple_resource_bundle` as a resource bundle target: [#2523](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2523)

### Fixed

* Fixed `-ivfsoverlay` for mixed-language targets: [#2478](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2478)
* `-oso_prefix` is now filtered from `link.params`: [#2505](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2505)
* Fixed a Starlark performance improvement when using bzlmod: [#2510](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2510) and [#2530](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2530)
* Fixed a BwX mode Xcode 15 cyclic dependency error: [#2483](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2483)
* Fixed inherited build settings: [#2531](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2531)
* Fixed running BwB unit tests on device: [#2534](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2534)

### Ruleset Development Changes

* Bumped minimum macOS for tools to 13.0: [#2475](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2475)

<a id="1.9.1"></a>
## [1.9.1] - 2023-08-14

[1.9.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.9.1

### Adjusted

* Bundle name, instead of module name, is now used in target disambiguation: [#2459](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2459)
* Changed how host output groups are set in fallback case: [#2461](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2461)

### Fixed

* Fixed quoting of flags in `SWIFT_OTHER_FLAGS`: [#2454](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2454)
* Fixed rules_ios `.xccurrentversion` collection: [#2457](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2457) and [#2465](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2465)
* Fixed BwX resource bundle Info.plist regression: 2466

<a id="1.9.0"></a>
## [1.9.0] - 2023-08-04

[1.9.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.9.0

### Adjusted

* `GENERATE_INFOPLIST_FILE` is not longer set: [#2379](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2379)
* Added an error message when `target_ids_list` is missing: [#2396](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2396)
* Changed “Command Line Tool” disambiguation to “Tool”: [#2434](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2434)
* Library module names are now preferred for target name disambiguation: [#2407](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2407)

### Fixed

* Fixed handling of conditional `bundle_name`: [#2368](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2368) and [#2375](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2375)
* Fixed Xcode set `LD_LIBRARY_PATH` and `SDKROOT` influencing `bazel build`: [#2373](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2373)
* Fixed handling of conditionally empty build setting values: [#2380](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2380)
* Fixed handling of generated `.xccurrentversion` files: [#2389](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2389)
* Fixed multiple target name disambiguation bugs: [#2415](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2415), [#2416](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2416), [#2414](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2414), [#2418](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2418), [#2419](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2419), [#2420](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2420), [#2429](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2429), [#2425](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2425), [#2432](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2432), and [#2435](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2435)
* Fixed wrong execution root being used in Index Build indexstore importing: [#2422](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2422) and [#2431](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2431)
* Fixed more cases of SourceKit (indexing) caching issues: [#2264](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2264) and [#2443](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2443)
* Fixed Swift generated header not being downloaded in BwB mode: [#2440](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2440)

<a id="1.8.1"></a>
## [1.8.1] - 2023-07-14

[1.8.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.8.1

### Fixed

* Fixed BwX not generating some Bazel generated files: [#2361](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2361)
* Fixed some transitive modulemaps not being generated: [#2362](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2362)
* Fixed `swift_debug_settings.py` not including testing search paths: [#2363](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2363) and [#2364](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2364)
* Fixed tool overrides still being set in BwB Index Build: [#2365](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2365)

<a id="1.8.0"></a>
## [1.8.0] - 2023-07-13

[1.8.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.8.0

### Adjusted

* Updated `index-import` to 5.8.0.1: [#2319](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2319) and [#2332](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2332)
* Renamed two build phases for consistency: [#2328](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2328)
* Added support for `/PLACEHOLDER_DEVELOPER_DIR` remapping: [#2331](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2331)
* The `DEVELOPER_DIR` regex is now restricted to the start of the line: [#2337](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2337)
* Adjusted `.pbxproj` formatting to match the way Xcode formats things: [#2339](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2339), [#2340](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2340), and [#2344](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2344)
* Indexes are now imported in Index Builds as well: [#2283](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2283)
* Project Format now supports Xcode 15: [#2343](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2343)
* `BAZELISK_SKIP_WRAPPER` is now captured in `bazel_env`: [#2357](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2357)

### Fixed

* `PBXProj.objectVersion` is now correctly set for Xcode 14+: [#2341](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2341)
* Fixed `libtool` version check in Xcode 15: [#2359](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2359)
* Tool overrides are now unset in the in `BazelDependencies` target: [#2358](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2358)

<a id="1.7.1"></a>
## [1.7.1] - 2023-06-20

[1.7.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.7.1

### Adjusted

* Added a usual error message when no diagnostics are parsed: [#2286](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2286)
* Added support for `swift_compiler_plugin` targets: [#2293](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2293)
* We now set `--repo_env=XCODE_VERSION`: [#2287](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2287)

### Fixed

* Fixed replacement label handling when wrapped in a macro: [#2291](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2291)
* Fixed BwX Swift testing search paths: [#2295](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2295)
* Fixed possible `bazel build` output truncation: [#2282](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2282)
* Fixed indexing of Swift macros: [#2292](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2292)
* Fixed Swift macros in BwX mode: [#2294](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2294)

<a id="1.7.0"></a>
## [1.7.0] - 2023-06-07

[1.7.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.7.0

### Adjusted

* All clang flag processing has been moved into the execution phase: [#2212](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2212)
* Application schemes are now sorted before other auto generated schemes: [#2211](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2211)
* Removed special handling for `-strict-concurrency`: [#2214](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2214)
* Removed special handling for `-enable-testing`: [#2215](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2215)
* Removed special handling for `SWIFT_OPTIMIZATION_LEVEL`: [#2227](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2227)
* Removed special handling of `ENABLE_STRICT_OBJC_MSGSEND`: [#2233](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2233)
* Moved generator package directory to `/var/tmp`: [#2252](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2252)
* The non-`=` version of `-working-directory` is now used: [#2254](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2254)
* `SWIFT_INCLUDE_PATHS` is no longer set in BwB mode: [#2245](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2245) and [#2277](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2277)
* `-I`, `-explicit-swift-module-map-file`, and `-vfsoverlay` are now set in `OTHER_SWIFT_FLAGS`: [#2256](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2256)
* `-F` is now set in `OTHER_SWIFT_FLAGS`: [#2258](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2258) and [#2263](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2263)
* `PROJECT_DIR` is now used instead of `CURRENT_EXECUTION_ROOT`: [#2259](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2259)
* `$(BAZEL_OUT)` is now used to reference compile params files: [#2260](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2260)
* Paths are now always absolute in `swift.compile.params` and `OTHER_SWIFT_FLAGS`: [#2261](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2261), [#2265](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2265), [#2267](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2267), and [#2269](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2269)
* `swiftc_stub` now errors out instead of warning: [#2278](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2278)
* Removed unnecessary dependencies from release archive: [#2279](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2279)

### Fixed

* `__BAZEL_` variables ar now replaced in `swift_debug_sttings.py`: [#2213](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2213)
* Development region is now properly set in `PBXProject.knownRegions`: [#2228](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2228)
* Fixed tests in custom schemes when `ios_unit_test.bundle_name` is used: [#2248](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2248)
* Fixed `test_suite` label creation if using bzlmod: [#2249](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2249)
* Fixed quoting of string defines in `{c,cxx}.compile.params`: [#2262](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2262)
* Builds now properly error out when using an `.xcworkspace`: [#2273](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2273)
* Fixed `swiftc_stub` with Xcode 15: [#2276](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2276)
* Fixed handling of build configuration in custom schemes: [#2274](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2274)

<a id="1.6.0"></a>
## [1.6.0] - 2023-05-18

[1.6.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.6.0

### New

* `test_suite` targets can now be specified in `xcodeproj.top_level_targets`: [#2184](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2184)
* `ios_*_test_suite` targets can now be specified in `xcodeproj.top_level_targets`: [#2196](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2196)
* Added a `bzl_library` target for xcodeproj files: [#2204](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2204)

### Adjusted

* Optimized project generation: [#2129](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2129), [#2130](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2130), [#2134](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2134), [#2138](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2138), [#2136](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2136), [#2137](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2137), [#2174](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2174), and [#2208](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2208)
* Swift and Objective-C targets can now merge into the same terminal target: [#2131](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2131), [#2146](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2146), and [#2150](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2150)
* All symlinks are now resolved to their target file: [#2147](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2147)
* Schemes are now sorted: [#2151](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2151)
* The `Bazel Build` script is now consistently named and structured: [#2164](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2164) and [#2177](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2177)
* App extensions can no longer be specified in `xcodeproj.top_level_targets`: [#2183](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2183)

### Fixed

* Fixed a target consolidation crash: [#2195](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2195)
* Fixed `xcodeproj.xcode_configurations` not supporting Starlark build settings with bzlmod enabled: [#2191](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2191)
* `{resource_,}filegroups` not belonging to focused targets are now properly excluded from the generated project: [#2159](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2159)

<a id="1.5.1"></a>
## [1.5.1] - 2023-04-26

[1.5.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.5.1

### Adjusted

* More optimizations: [#2118](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2118), [#2119](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2119), [#2114](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2114), [#2115](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2115), and [#2116](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2116)

### Fixed

* Fixed `_write_target_ids_list` regression: [#2121](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2121)
* Fixed `_skip_target` handling of `compilation_providers.merge`: [#2123](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2123)

<a id="1.5.0"></a>
## [1.5.0] - 2023-04-25

[1.5.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.5.0

### Adjusted

* Upgraded XcodeProj to 8.9.0: [#2048](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2048)
* Lots of generation memory and cpu reduction optimizations: [#2022](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2022), [#2008](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2008), [#2025](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2025), [#2026](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2026), [#2030](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2030), [#2028](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2028), [#2032](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2032), [#2033](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2033), [#2031](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2031), [#2034](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2034), [#2037](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2037), [#2038](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2038), [#2043](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2043), [#2042](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2042), [#2045](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2045), [#2049](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2049), [#2052](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2052), [#2053](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2053), [#2054](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2054), [#2056](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2056), [#2059](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2059), [#2060](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2060), [#2067](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2067), [#2073](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2073), [#2063](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2063), [#2076](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2076), [#2079](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2079), [#2081](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2081), [#2082](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2082), [#2083](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2083), [#2087](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2087), [#2086](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2086), [#2090](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2090), [#2089](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2089), [#2094](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2094), [#2095](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2095), [#2096](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2096), [#2098](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2098), [#2099](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2099), [#2104](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2104), [#2105](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2105), [#2102](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2102), [#2107](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2107), [#2101](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2101), [#2112](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2112), and [#2110](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2110)
  * Compiler flags are now passed with param files: [#2016](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2016)
  * Simplified `DEBUG_INFORMATION_FORMAT` calculation: [#2071](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2071) and [#2100](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2100)
  * Merged the `bc` and `bg` output groups: [#2074](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2074)
* Reorder default PATH by @thii in https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2039
* Added code highlighting to `Podfile` files: [#2041](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2041)
* Removed extra quoting in `link.params` files: [#2061](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2061)
* Added support for multiple compile targets: [#2072](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2072)

### Fixed

* Fixed output base when using `--config=indexbuild` with the command-line API: [#2027](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2027)
* Fixed `create_lldbinit.sh` not appending content to a new line: [#2036](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2036)
* Fixed `import_indexstores.sh` when using `swift.remap_xcode_path`: 2064
* Fixed space handling linkopts: [#2062](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2062) and [#2069](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2069)
* Fixed space handling in `target.swift-extra-clang-flags`: [#2070](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2070)
* Fixed custom bundle extension handling: [#2093](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2093)

<a id="1.4.0"></a>
## [1.4.0] - 2023-04-12

[1.4.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.4.0

### New

* Added support for `cc_library.implementation_deps`: [#1933](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1933), [#1967](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1967), and [#2015](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2015)
* Added the [`xcodeproj.bazel_env` attribute](docs/bazel.md#xcodeproj-bazel_env): [#1990](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1990)
* Added the [`xcodeprojfail_for_invalid_extra_files_targets` attribute](docs/bazel.md#xcodeproj-fail_for_invalid_extra_files_targets): [#1977](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1977)

### Adjusted

* Upgraded swift-collections to 1.0.4: [#1960](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1960)
* Spotlight is now prevented from indexing our Bazel output bases: [#2013](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2013)
* Improved target merging: [#1902](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1902), [#1928](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1928), and [#1946](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1946)
* Improved CC dynamic linking support: [#1943](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1943), [#1944](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1944), [#1942](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1942), and [#1949](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1949)
* Various project generation performance improvements: [#1957](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1957), [#1958](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1958), [#1961](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1961), [#1962](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1962), [#1972](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1972), [#1973](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1973), [#1974](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1974), [#1976](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1976), [#1978](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1978), [#1979](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1979), [#1980](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1980), [#1985](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1985), [#1986](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1986), [#1998](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1998), [#2001](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2001), [#2003](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2003), [#2004](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2004), and [#2005](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2005)
* Builds in Xcode now verify that the requested target ids are still valid: [#1982](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1982)
* `PATH` is now set to `/usr/bin:/bin` when `bazel_path` (e.g. `bazel`) is called to generate a project or build inside of Xcode: [#1950](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1950)
  * To adjust this behavior, set [`xcodeproj.bazel_env`](docs/bazel.md#xcodeproj-bazel_env).
* Improved progress messages for project generation: [#1999](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1999) and [#2002](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2002)
* Improved error message when decoding fails: [#1975](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1975)
* You can now the generator label in the command-line API: [#2011](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2011)

### Fixed

* Fixed Xcode 14.3 support: [#1937](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1937) and [#1981](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1981)
* Generating multiple targets in the same workspace now works correctly: [#1992](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1992), [#2000](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2000), and [#2012](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2012)
* Fixed some focused targets issues: [#1923](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1923), [#1930](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1930), [#1983](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1983), [#1994](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1994), [#1995](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1995), and [#1997](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1997)
* Fixed handling of bzlmod external targets: [#1926](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1926)
* Fixed handling of `--force_pic`: [#1939](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1939)
* Fixed CC optimization level flag calculations: [#2017](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2017)
* Fixed command-line API to work with the `dump` and `shutdown` commands: [#2019](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/2019)
* Fixed specs collection: [#1966](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1966)
* Fixed BwB test action env variables for custom schemes without launch actions: [#1955](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1955)
* Fixed BwX `swift_debug_settings.py` generation: [#1971](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1971)

<a id="1.3.3"></a>
## [1.3.3] - 2023-03-24

[1.3.3]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.3.3

### Adjusted

* Upgraded rules_swift to 1.7.1 when not using Bzlmod: [#1914](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1914)
* Upgraded rules_apple to 2.2.0 when not using Bzlmod: [#1916](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1916)
* Logs are now colorized: [#1907](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1907)
* Adjusted target merging to account for targets that are present in Xcode: [#1903](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1903)

### Fixed

* Fixed linux builds: [#1896](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1896)
* Fixed target focusing in less than Bazel 6: [#1913](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1913)
* Illegal characters are now removed from custom scheme names: [#1915](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1915)
* `--output_base` set on command-line is now respected: [#1917](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1917)

<a id="1.3.2"></a>
## [1.3.2] - 2023-03-17

[1.3.2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.3.2

### Fixed

* Fixed handling of multiline `xcodeproj.{pre,post}_build` values: [#1892](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1892)
* Fixed visibility with bzlmod: [#1895](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1895)
  * You should change your `visibility`/`package_group`s to mention the `@rules_xcodeproj//xcodeproj:generated` `package_group`

<a id="1.3.1"></a>
## [1.3.1] - 2023-03-16

[1.3.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.3.1

### Adjusted

* Moved generated generators to an external repository: [#1876](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1876), [#1886](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1886), and [#1887](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1887)
  * The `.rules_xcodeproj` directory isn't created anymore, and you can remove it from ignore lists
  * You'll need to change your `visibility`/`package_group`s to mention `@rules_xcodeproj_generated//:__subpackages__`
* Improved the efficency of various Stalark code: [#1866](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1866), [#1867](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1867), [#1868](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1868), [#1869](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1869), [#1871](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1871), [#1872](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1872), [#1873](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1873), [#1874](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1874), [#1879](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1879), [#1882](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1882), [#1884](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1884), [#1883](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1883), and [#1885](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1885)

### Fixed

* Fixed handling of `-Xcc -iquote -Xcc path` type flags: [#1875](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1875)
* Fixed handling of some quoted paths in `link_params_processor.py`: [#1877](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1877)
* Fixed device-only project generation: [#1880](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1880)

<a id="1.3.0"></a>
## [1.3.0] - 2023-03-15

[1.3.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.3.0

### New

* Added support for multiple Xcode configurations with the new [`xcodeproj.xcode_configurations` attribute](docs/bazel.md#xcodeproj-xcode_configurations): [#1789](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1789), [#1791](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1791), [#1793](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1793), [#1796](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1796), [#1797](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1797), [#1799](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1799), [#1800](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1800), [#1801](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1801), [#1806](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1806), [#1807](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1807), [#1815](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1815), [#1858](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1858)
* Added the [`organization_name` parameter to `project_options`](docs/bazel.md#project_options-organization_name) parameter: [#1804](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1804)
* Added the [`profile_action` parameter to `xcode_schemes.scheme`](docs/bazel.md#xcode_schemes.scheme-profile_action): [#1819](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1819) and [#1835](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1835)

### Adjusted

* Changed the default name of the repo to `@rules_xcodeproj`: [#1814](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1814)
  * **You should do this as well**
  * First change the repo name from `com_github_buildbuddy_io_rules_xcodeproj` to `rules_xcodeproj` in your `MODULE.bazel` or `WORKSPACE` file
  * Then run this `buildifier` command: `buildozer 'substitute_load com_github_buildbuddy_io_rules_xcodeproj rules_xcodeproj' '//...:*'`
* Optimized project generation to be faster: [#1788](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1788), [#1825](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1825), [#1826](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1826), [#1827](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1827), [#1829](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1829), [#1830](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1830), [#1831](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1831), [#1832](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1832), [#1833](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1833), [#1834](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1834), [#1836](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1836), [#1838](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1838), [#1839](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1839), [#1840](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1840), [#1841](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1841), [#1842](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1842), [#1843](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1843), [#1845](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1845), [#1844](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1844), [#1848](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1848), and [#1850](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1850)
* Bazel targets with conditional dependencies will consolidate to few targets now: [#1805](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1805)
* User compiler flags are now processed by the cc_toolchain: [#1810](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1810)
* Improved handling of dSYMs: [#1856](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1856) and [#1767](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1767)
* Removed resource files from conditional source files in BwB mode: [#1863](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1863)
* Some small scheme generation improvements: [#1816](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1816), [#1817](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1817), and [#1818](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1818)

### Fixed

* Fixed `extra_files` logic for merged targets when using focused targets: [#1782](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1782)
* Stale files in `.xcodeproj/rules_xcodeproj/bazel` are now properly deleted: [#1803](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1803)
* Fixed CC `copts` tokenization: [#1811](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1811)
* Fixed `bazelisk` invoking in `runner.sh`: [#1849](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1849)
* Fixed handling of large number of linker flags: [#1862](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1862)

<a id="1.2.0"></a>
## [1.2.0] - 2023-02-22

[1.2.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.2.0

### New

* Added [`xcodeproj.project_options`](docs/bazel.md#project_options): [#1756](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1756)

### Adjusted

* We now use the first architecture when importing indexing data if multiple are set: [#1763](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1763)
* We now set the full range for `SUPPORTED_PLATFORMS` in normal builds: [#1762](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1762)
* `--cache_computed_file_digests` is now set to a higher value by default: [#1765](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1765)
* Upgraded index-import to 5.7.0.1: [#1770](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1770)
* Upgraded rules_swift to 1.6.0: [#1772](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1772)
* Upgraded rules_apple to 2.1.0: [#1777](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1777)

### Fixed

* Fixed LLDB issue with testable targets: [#1755](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1755)
* Fixed handling of relative paths in index unit files: [#1761](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1761)
* Fixed project generation when merge target becomes unfocused: [#1769](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1769)
* Fixed (in Bazel 6.1+) schemes not being able to reference external targets when using Bzlmod: [#1771](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1771)
* Fixed generated `*_framework.exported_symbols_list` in BwX mode: [#1780](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1780)

<a id="1.1.0"></a>
## [1.1.0] - 2023-02-06

[1.1.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.1.0

> This release is the same as the 1.0.1 release, with the version changed to 1.1.0.

See the [1.0.1 release](#1.0.1) for details.

<a id="1.0.1"></a>
## [1.0.1] - 2023-02-06

[1.0.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.0.1

> This release is the same as the 1.0.0rc3 release, with the version changed to 1.0.1.

This is the first release with a non-zero major version. Since we are using [Semantic Versioning](https://semver.org/spec/v2.0.0.html) for **rules_xcodeproj**, from this release forward there won’t be breaking changes unless we increment our major version as well.[^compatibility_level][^unstable_apis]

Since this is the first major release, every feature can be seen as “new”, so here is the state of all features in the release:

- Full support for Xcode features:
  - Indexing (i.e. autocomplete, syntax highlighting, jump to definition)
  - Debugging
  - Runtime sanitizers
  - Inline warnings and errors
  - Fix-its (currently only in BwX mode)
  - Test selection and running
  - Embedded Targets (App Clips, App Extensions, and Watch Apps)
  - Dynamic frameworks
  - SwiftUI Previews
- Focused Projects
  - Include a subset of your targets in Xcode
  - Unfocused targets are built with Bazel
  - Works in BwX mode as well!
- Comprehensive Bazel rules support
  - Core Bazel C/C++/Objective-C
  - rules_swift
  - rules_apple
  - rules_ios
  - Most likely your custom rules as well!
- Minimal configuration needed
- Multiple ways of building your project in Xcode
  - Build your Bazel targets with Bazel (a.k.a Build with Bazel or BwB mode)
  - Build your Bazel targets with Xcode, _not_ Bazel (a.k.a. Build with Xcode or BwX mode)[^bwx_warning]

[^compatibility_level]: Bzlmod has a different way of marking breaking changes with [`module.compatibility_level`](https://bazel.build/versions/6.0.0/rules/lib/globals#module.compatibility_level). We will increment both the major version and the `compatibility_level` in tandum.
[^unstable_apis]: There are some APIs that have been explicitly marked as unstable, such as the `XcodeProjAutomaticTargetProcessingInfo` and `XcodeProjInfo` providers. Changes to unstable APIs do not count as breaking changes.
[^bwx_warning]: Build with Bazel mode is the build mode with first class support. We will try to make Build with Xcode mode work with every project, but there are limitations that can [make the experience subpar](/docs/faq.md#why-do-some-of-my-swift_librarys-compile-twice-in-bwx-mode), or not work at all. We recommend using BwB mode if possible.

<a id="1.0.0rc3"></a>
## [1.0.0rc3] - 2023-02-03

[1.0.0rc3]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.0.0rc3

* Added `xcodeproj.install_directory` attribute: [#1723](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1723)
* Added support for rules_apple's `*_build_test` rules: [#1730](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1730)
* Fixed compiling of `objc_library` targets that don't correctly set `testonly`: [#1743](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1743)
* Fixed indexing of rules that use `-vfsoverlay`: [#1726](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1726)
* Fixed `args`, `envs`, and `xccurrentversions` related generation errors when using focused targets: [#1728](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1728) and [#1729](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1729)
* Fixed `cp -c` issue with multiple volumes: [#1747](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1747)

<a id="1.0.0rc2"></a>
## [1.0.0rc2] - 2023-02-01

[1.0.0rc2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.0.0rc2

* dSYMs are now copied into Derived Data in BwB mode: [#1626](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1626)
* Non-source `*_library` targets no longer generate Xcode targets (again): [#1713](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1713)
* Target merging restrictions now apply for non-Swift targets as well: [#1717](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1717)
* Fixed breakpoints when `~/.lldbinit-Xcode` exists: [#1720](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1720)
* Fixed BwX handling of `--apple_generate_dsym`: [#1714](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1714)


See the [1.0.0rc1 release note](https://github.com/buildbuddy-io/rules_xcodeproj/releases/tag/1.0.0rc1) for more details of what is in the 1.0.0rc release.

<a id="1.0.0rc1"></a>
## [1.0.0rc1] - 2023-01-30

[1.0.0rc1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/1.0.0rc1

### ⚠️ Breaking Changes ⚠️

* Removed deprecated `xcodeproj.bzl`: [#1695](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1695)
* Added unstable API warning to public providers: [#1703](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1703)

### Fixes and Improvements

* Added support for `implementation_deps`: [#1664](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1664)
* Some of the tools used in project generation are now prebuilt in `release.tar.gz`: [#1680](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1680) and [#1682](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1682)
* Moved `swift_debug_settings.py` creation to Starlark: [#1666](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1666), [#1667](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1667), [#1669](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1669), [#1670](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1670), and [#1671](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1671)
* Reduced the size of the intermediate json files used during project generation: [#1686](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1686), [#1688](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1688), [#1689](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1689), [#1691](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1691), [#1692](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1692), [#1693](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1693), and [#1694](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1694)
* Improved how resource bundles interact with `xcodeproj,{un,}focused_targets`: [#1699](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1699), [#1700](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1700), and [#1702](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1702)
* Project generation now sets `--xcode_version`, to try to reduce analysis cache trashing: [#1708](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1708)
* Fixed breakpoint resolution when using Test and Profile actions: [#1658](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1658)
* Fixed BwB UI Test Swift debugging: [#1661](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1661) and [#1662](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1662)
* Fixed BwX handling of `-D_FORTIFY_SOURCE` when using ASAN: [#1707](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1707)
* Fixed BwB handling of `-O` when using Runtime Sanitizers: [#1701](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1701)

<a id="0.12.3"></a>
## [0.12.3] - 2023-01-25

[0.12.3]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.12.3

* Improved handling of rules_ios's `apple_framework.vendored_xcframeworks`: [#1641](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1641)
* Continued work on passing through compiler flags directly from Bazel: [#1617](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1617), [#1620](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1620), [#1627](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1627), [#1629](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1629), [#1630](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1630), [#1632](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1632), [#1633](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1633), [#1636](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1636), [#1637](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1637), [#1638](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1638)
* We no longer set `OTHER_CFLAGS`/`OTHER_CPLUSPLUSFLAGS` when not applicable: [#1628](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1628) and [#1635](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1635)
* Fixed stale BwB installs: [#1631](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1631)
* Fixed some lldb clang compilation issues regarding framework search paths: [#1621](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1621) and [#1622](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1622)
* Fixed some BwX compiling regressions: [#1642](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1642) and [#1647](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1647)
* Fixed some BwX linking regressions: [#1639](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1639) and [#1640](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1640)
* Fixed `depset` mutability issue: [#1615](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1615)


See the [0.12.0 release note](https://github.com/buildbuddy-io/rules_xcodeproj/releases/tag/0.12.0) for more details of what is in the 0.12.0 release.

<a id="0.12.2"></a>
## [0.12.2] - 2023-01-19

[0.12.2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.12.2

* Fixed handling of custom schemes and focused targets labels when using bzlmod (though [only if they aren't labels to external repositories](https://github.com/bazelbuild/bazel/issues/17260)): [#1599](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1599), [#1601](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1601), and [#1605](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1605)
* Fixed handling of absolute paths in `build_setting_path()`: [#1602](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1602)
* Fixed handling of `--config`: [#1604](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1604)
* Header search paths are no longer made absolute: [#1603](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1603)


See the [0.12.0 release note](https://github.com/buildbuddy-io/rules_xcodeproj/releases/tag/0.12.0) for more details of what is in the 0.12.0 release.

<a id="0.12.0"></a>
## [0.12.0] - 2023-01-18

[0.12.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.12.0

### ⚠️ Breaking Changes ⚠️

* VFS overlays (e.g. [`swift.vfsoverlay`](https://github.com/bazelbuild/rules_swift/blob/1.5.1/swift/internal/feature_names.bzl#L228-L233) or rules_ios's `apple_library`) are no longer supported in BwX mode: [#1559](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1559)

### New

* Started to add support for bzlmod: [#1502](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1502)

### Fixes and Improvements

* Upgraded rules_swift to 1.5.1: [#1571](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1571)
* Upgraded rules_apple to 2.0.0 (when using Bazel 6): [#1503](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1503)
* App extensions and watchOS apps are now debuggable: [#1536](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1536)
* **rules_xcodeproj**’s `.lldbinit` is now created in a launch pre-action: [#1532](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1532), [#1533](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1533), [#1534](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1534), [#1535](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1535), and [#1587](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1587)
* The `link.params` file is now lazily generated, and has most flags passed through directly from Bazel: [#1521](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1521), [#1522](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1522), [#1538](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1538), [#1541](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1541), [#1542](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1542), [#1543](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1543), [#1544](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1544), [#1546](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1546), [#1547](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1547), [#1548](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1548), [#1549](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1549), [#1551](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1551), [#1557](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1557), [#1569](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1569), [#1570](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1570), [#1572](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1572), [#1582](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1582), and [#1595](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1595)
* Started work on passing through compiler flags directly from Bazel: [#1565](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1565), [#1566](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1566), [#1568](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1568), [#1569](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1569), [#1570](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1570), [#1573](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1573), [#1574](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1574), [#1575](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1575), [#1576](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1576), [#1577](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1577), [#1578](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1578), [#1579](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1579), [#1583](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1583), [#1581](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1581), [#1592](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1592), and [#1595](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1595)
* BwX mode now picks up additional "headers" (e.g. hmaps), though see [this FAQ](https://github.com/buildbuddy-io/rules_xcodeproj/blob/0.12.0/docs/faq.md#why-do-some-of-my-swift_librarys-compile-twice-in-bwx-mode) for caveats : [#1539](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1539) and [#1540](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1540)
* Added support for command line args in test schemes: [#1520](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1520)
* If a custom scheme sets `custom_working_directory`, it's now also applied to the Profile action: [#1501](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1501)
* Improved iMessage app extension scheme creation: [#1531](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1531)
* Header-only libraries now are represented by Xcode targets: [#1494](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1494)
* The executable bit is now correctly set for all scripts embedded in the generated project: [#1527](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1527)
* Fixed BwX Swift debugging: [#1526](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1526) and [#1530](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1530)
* Fixed BwX Index Build failure: [#1552](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1552)
* Fixed incorrect BwB copy path for macOS tests: [#1593](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1593)
* Fixed search path references to `bazel-out` and `external` directories: [#1528](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1528)
* Fixed crash generating project with `apple_universal_binary`: [#1453](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1453)
* Fixed an unresolved breakpoints edge case: [#1588](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1588), [#1589](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1589), and [#1590](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1590)

<a id="0.11.0"></a>
## [0.11.0] - 2022-12-20

[0.11.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.11.0

### ⚠️ Breaking Changes ⚠️

* Team ID is now always required when using `xcode_provisioning_profile`: [#1397](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1397)
* Remove deprecated `device_and_simulator` rule: [#1391](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1391)

### New

* Added `xcodeproj.xcode_minimum_version`: [#1463](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1463), [#1464](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1464), and [#1465](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1465)
* Added a `--collect_specs` command-line option: [#1498](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1498)

### Fixes and Improvements

* Upgraded `index-import` to 5.7: [#1425](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1425)
* Upgraded rules_apple to 1.1.3: [#1427](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1427)
* Upgraded rules_swift to 1.4.0: [#1454](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1454)
* Upgraded ZippyJSON to 1.2.10: [#1469](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1469)
* Fixed indexing of external files: [#1382](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1382)
* Fixed BwB framework SwiftUI Previews: [#1388](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1388)
* Removed transition on `build_mode`, allowing cache sharing between BwB and BwX: [#1392](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1392), [#1393](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1393), [#1395](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1395), and [#1398](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1398)
* Optimized how many `XcodeProjInfo` providers are created: [#1394](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1394)
* Moved some path calculations into Starlark: [#1400](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1400), [#1402](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1402), [#1404](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1404), [#1405](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1405), [#1406](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1406), [#1407](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1407), [#1408](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1408), [#1409](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1409), [#1411](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1411), [#1413](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1413), [#1414](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1414), [#1415](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1415), [#1416](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1416), [#1417](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1417), [#1419](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1419), [#1420](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1420), [#1423](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1423), [#1426](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1426), [#1428](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1428), [#1429](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1429), [#1431](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1431), [#1432](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1432), [#1433](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1433), [#1434](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1434), [#1435](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1435), [#1436](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1436), [#1445](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1445), and [#1470](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1470)
* `--features=swift.use_global_module_cache` is now set in `xcodeproj.bazelrc`: [#1442](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1442)
* Fixed excessively long filelist paths: [#1458](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1458)
* Fixed debugging when using BwtB: [#1461](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1461)
* Fixed `lldb` error when `module` is `None`: [#1466](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1466)
* Improved BEP/BES performance: [#1472](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1472), [#1473](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1473), and [#1474](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1474)
* Improved performance generating large projects: [#1478](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1478), [#1479](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1479), [#1480](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1480), [#1481](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1481), [#1482](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1482), [#1483](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1483), and [#1485](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1485)
* Removed warning for pre and post scripts: [#1484](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1484)
* Fixed incremental device installs of iOS 16+ applications with extensions: [#1487](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1487)
* Fixed project generation when targets don't provide an `AppleResourceInfo` provider: [#1492](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1492)
* Renamed an internal argument to improve compatibility with `bazel` wrappers: [#1497](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1497)

<a id="0.10.2"></a>
## [0.10.2] - 2022-11-01

[0.10.2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.10.2

* Fixed handling of absolute paths in error messages: [#1379](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1379)
* Fixed capitalization of error messages: [#1380](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1380)
* Fixed indexing of generated and external sources: [#1381](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1381)

See the [0.10.0 release note](https://github.com/buildbuddy-io/rules_xcodeproj/releases/tag/0.10.0) for more details of what is in the 0.10.0 release.

<a id="0.10.1"></a>
## [0.10.1] - 2022-10-28

[0.10.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.10.1

* Fixed some BwX linker bugs

See the [0.10.0 release note](https://github.com/buildbuddy-io/rules_xcodeproj/releases/tag/0.10.0) for more details of what is in the 0.10.0 release.

<a id="0.10.0"></a>
## [0.10.0] - 2022-10-28

[0.10.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.10.0

### ⚠️ Breaking Changes ⚠️

* If you used the undocumented command-line API, it's been replaced by an official one (mentioned below). See the [new section in the Usage Guide](docs/usage.md#command-line-api) for more details.

### New

* Added official command-line API: [#1350](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1350) and [#1371](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1371)
* Added support for propagating env values from `*_test` rules: [#1275](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1275)
* Added `pre_post_actions` to `test_action`: [#1333](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1333)

### Fixes and Improvements

* Upgraded skylib to 1.3.0: [#1236](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1236)
* A separate output base is now used for building as well, reducing analysis cache invalidations: [#1221](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1221) and [#1264](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1264)
* Optimized BwB build performance by removing most target dependencies and target embedding: [#1238](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1238), [#1262](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1262), [#1271](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1271), [#1272](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1272), [#1273](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1273), [#1274](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1274), [#1276](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1276), [#1277](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1277), [#1278](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1278), [#1285](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1285), [#1288](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1288), [#1311](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1311), and [#1323](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1323)
* Improved the baseline BwtB experience: [#1239](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1239), [#1242](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1242), [#1300](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1300), and [#1306](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1306)
* Fixed scheme symlink creation: [#1279](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1279), [#1291](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1291), and [#1301](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1301)
* Refactored file path resolution: [#1241](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1241),[#1243](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1243), [#1246](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1246), [#1250](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1250), and [#1347](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1347)
* Fixed `-add_ast_path` for merged targets: [#1245](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1245)
* Changed `PROJECT_DIR` to Bazel's execution root: [#1249](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1249), [#1251](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1251), [#1252](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1252), [#1260](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1260), [#1263](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1263), [#1286](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1286), [#1287](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1287), [#1293](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1293), [#1295](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1295), [#1299](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1299), [#1304](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1304), [#1327](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1327), and [#1329](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1329)
* We now work around Bazel's handling of `DEVELOPER_DIR`: [#1257](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1257), [#1258](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1258), and [#1259](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1259)
* Fixed handling of top-level linkopts: [#1248](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1248)
* We now apply normal configuration segregation to `BUILD_DIR`: [#1267](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1267) and [#1305](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1305)
* Fixed BwB Indexing handling of modulemaps: [#1269](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1269)
* Removed env variable filtering: [#1280](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1280)
* Removed use of output group maps: [#1307](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1307)
* Fixed and optimized `rsync` exclude files: [#1309](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1309), [#1355](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1355), [#1357](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1357), [#1358](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1358), [#1362](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1362), and [#1364](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1364)
* We now set a pattern override for BuildBuddy, to improve the look of invocations: [#1310](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1310)
* Fixed BwX Swift generated header path for merged targets (i.e. frameworks): [#1313](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1313)
* Added `-emit-symbol-graph-dir` to filtered swiftcopts: [#1316](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1316)
* Fixed target dependency to merged target: [#1315](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1315)
* Added support for mixed language modules: [#1317](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1317), [#1318](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1318), [#1319](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1319), and [#1328](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1328)
* Fixed `test_action.diagnostics` propagation: [#1321](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1321)
* Removed extra `bazel info` calls: [#1326](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1326), [#1345](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1345), [#1346](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1346), and [#1348](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1348)
* We now symlink instead of copy BwB SwiftUI Previews framework dependencies: [#1330](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1330) and [#1363](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1363)
* We now properly set `ENABLE_STRICT_OBJC_MSGSEND`: [#1331](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1331)
* Improved performance of project generation: [#1335](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1335), [#1337](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1337), [#1338](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1338), [#1339](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1339), [#1341](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1341), and [#1343](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1343)
* Prevent `bazel clean` from affecting **rules_xcodeproj**’s output base (use the new command-line API to clean it instead): [#1353](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1353)
* Fixed BwB debugging of framework targets: [#1356](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1356)
* Moved target merging into Starlark: [#1366](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1366), [#1367](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1367), [#1368](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1368), [#1369](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1369), and [#1370](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1370)

<a id="0.9.0"></a>
## [0.9.0] - 2022-10-06

[0.9.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.9.0

### ⚠️ Breaking Changes ⚠️

* Moved public rules and macros to `xcodeproj/defs.bzl`: [#1115](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1115)

### New

* Added support for custom pre and post build scripts in BwB mode: [#1117](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1117), [#1129](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1129), and [#1156](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1156)
* Added support for Runtime Sanitizers: [#1134](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1134), [#1137](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1137), [#1138](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1138), [#1127](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1127), [#1142](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1142), [#1155](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1155), [#1168](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1168), [#1193](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1193), [#1195](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1195), [#1196](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1196), [#1209](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1209), [#1232](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1232), [#1233](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1233), [#1234](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1234), and [#1235](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1235)
* Added support for dynamic frameworks: [#1133](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1133), [#1135](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1135), [#1136](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1136), [#1140](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1140), [#1141](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1141), [#1145](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1145), [#1146](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1146), [#1148](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1148), [#1149](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1149), [#1150](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1150), [#1151](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1151), [#1157](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1157), [#1160](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1160), [#1162](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1162), [#1164](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1164), [#1166](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1166), [#1163](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1163), [#1165](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1165), [#1178](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1178), [#1183](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1183), [#1190](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1190), [#1191](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1191), [#1192](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1192), [#1199](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1199), [#1201](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1201), and [#1200](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1200)
* Added `top_level_targets` convenience function: [#1207](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1207) and [#1219](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1219)

### Fixes and Improvements

* Added support for `STRICT_SWIFT_CONCURRENCY`: [#1109](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1109)
* Updated rules_swift to 1.2.0 and rules_apple to 1.1.2: [#1112](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1112)
* Fixed issue with `-fmodule-map-file` in BwX mode: [#1121](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1121)
* Fixed Xcode 14 resource bundle code signing: [#1124](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1124)
* Added support for Alternate Icons: [#1125](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1125)
* Xcode no longer sets default search paths: [#1161](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1161)
* Added support for `--features=swift.file_prefix_map`: [#1173](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1173)
* Improved libtool stub performance: [#1185](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1185)
* Improved file unfocusing: [#1187](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1187)
* Improved error handling of XCBuildData caches: [#1188](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1188) and [#1213](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1213)
* Fixed handling of implicit SDK frameworks: [#1202](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1202)
* Fixed handling of `None` `swift.module.swiftsourceinfo`: [#1204](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1204)
* Fixed handling of `None` `module.clang`: [#1205](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1205)
* Fixed handling of `None` `AppleBundleInfo.bundle_id`: [#1211](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1211)
* Converted swiftc stub to a compiled binary: [#1198](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1198), [#1225](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1225), and [#1227](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1227)
* Fixed `--incompatible_unambiguous_label_stringification` handling: [#1218](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1218)
* We now apply the same `env -i` during project generation: [#1220](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1220) and [#1222](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1222)
* Generated source files are now always downloaded from remote caches: [#1223](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1223)
* Added index-while-building to SwiftUI Preview builds: [#1230](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1230)
* Schemes no longer have `Find Implicit Dependencies` checked: [#1226](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1226)

<a id="0.8.0"></a>
## [0.8.0] - 2022-09-15

[0.8.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.8.0

### ⚠️ Breaking Changes ⚠️

* `device_and_simulator` has been deprecated. Use the new `top_level_target.target_environments` argument instead: [#965](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/965)
* `xcode_provisioning_profile` has moved from `xcodeproj/experimental.bzl` to `xcodeproj/xcodeproj.bzl`: [#1069](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1069)
* `xcodeproj.build_mode` now defaults to `"bazel"`: [#1022](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1022)
* It is now an error to list non-top-level targets in `top_level_targets`: [#1104](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1104)

### New

* The project generator is now run inside a runner script, and allows for configuration via Bazel configs: [#911](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/911), [#950](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/950), [#952](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/952), [#990](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/990), [#1061](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1061), [#1062](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1062), and [#1075](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1075)
    * This means that most command-line flags you pass to `bazel run //:xcodeproj` are ignored
    * To adjust the project generation, use the newly available [Bazel configs](https://github.com/buildbuddy-io/rules_xcodeproj/blob/0.8.0/docs/usage.md#bazel-configs)
* Bazel-built Swift now uses index-while-building: [#1040](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1040), [#1043](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1043), [#1096](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1096), and [#1098](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1098)
* Added support for custom working directory in custom scheme launch actions: [#1051](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1051), [#1074](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1074), and [#1076](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1076)
* Added support for custom Swift toolchains: [#1027](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1027)
* Added support for adding extra files to the project: [#1080](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1080)
* Added support for custom scheme pre and post actions: [#1047](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1047)

### Fixes and Improvements

* Test issues now navigate to their source location in BwB mode: [#961](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/961)
* Test targets now use their non-internal name: [#980](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/980) and [#1044](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1044)
* All versions of Info.plist for a given target are now generated when building: [#985](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/985)
* Added support for the "Compile File" command: [#976](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/976)
* Fixed handling of missing `AppleBinaryInfo.infoplist`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/1002
* (Mostly) fixed handling of `apple_universal_binary` targets: [#1003](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1003), [#1004](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1004), and [#1034](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1034)
* The generator is now a universal target with a set minimum OS: [#1008](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1008)
* Extracted `bazel_build.sh` to a script: [#1009](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1009) and [#1016](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1016)
* Fixed quoting of single-file build settings: [#1045](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1045)
* Improved handling of `top_level_cache_buster`: [#1050](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1050) and [#1103](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1103)
* Index Build's bazel outputs are now stored inside a directory of the normal Bazel output: [#1053](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1053)
* Binary rules are now codesigned, fixing the Memory Graph Debugger: [#1058](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1058)
* Fixed edge-case building of unfocused dependencies: [#1093](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1093)
* Bazel now uses the correct Xcode version when compiling: [#1099](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1099), [#1100](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1100), and [#1102](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1102)
* Merged library targets are now automatically focused when their destination target is focused: [#1108](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/1108)

<a id="0.7.1"></a>
## [0.7.1] - 2022-08-25

[0.7.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.7.1

### New

* Added `{device,simulator}_only_targets` attributes to `device_and_simulator`: [#925](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/925)
* Added rules documentation: [#936](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/936), [#944](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/944), [#964](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/964), [#969](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/969), and [#974](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/974)

### Fixes and Improvements

* Improved scheme generation: [#890](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/890), [#901](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/901), [#905](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/905), [#909](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/909), [#934](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/934), [#940](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/940), [#942](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/942), [#956](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/956), [#962](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/962), [#963](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/963), [#966](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/966)
* Improved Xcode 14 support: [#892](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/892)
* Fixed issues not navigating to source files in BwB mode: [#893](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/893)
* Fixed VFS overlay generation: [#898](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/898), [#918](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/918), [#919](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/919), [#921](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/921), and [#941](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/941)
* Fixed indexing of `local_repository` and `new_local_repository` targets: [#900](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/900) and [#929](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/929)
* Fixed linking BwB SwiftUI Previews: [#922](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/922)
* Fixed `external/` header search paths: [#923](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/923)
* Unfocusing of "invalid" labels is now supported: [#938](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/938)
* Targets can now merge into multiple top-level targets: [#937](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/937)
* Top-level bundle targets can now have multiple dependencies: [#939](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/939)
* Fixed `-D` quote handing: [#948](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/948)
* The `ASSETCATALOG_COMPILER_APPICON_NAME` build setting is now set: [#932](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/932)
* Fixed Resource bundle detection: [#958](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/958)
* Added `no-remote` to project generation: [#972](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/972)
* Upgrade warnings are now disabled: [#970](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/970)

<a id="0.7.0"></a>
## [0.7.0] - 2022-08-05

[0.7.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.7.0

### ⚠️ Breaking Changes ⚠️

* `xcodeproj`'s `targets` attribute has been renamed to `top_level_targets`: [#831](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/831)
    * This is to better reflect what types of targets you should list here. Listing dependencies of top-level targets (including `device_and_simulator`) will result in additional incorrectly configured targets in your project.

### New

* Added C++ support to BwB: [#787](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/787)
* Added initial support for custom schemes: [#803](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/803), [#808](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/808), [#809](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/809)
* Added support for manually defined Focused Projects: [#826](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/826)
    * These are defined by specifying labels in the `focused_targets` and/or `unfocused_targets` attributes on `xcodeproj`

### Fixes and Improvements

* Disabled BES for Index Builds: [#736](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/736)
* Improved handling of `linkopts`: [#738](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/738), [#737](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/737), [#745](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/745), [#747](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/747), [#746](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/746), [#750](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/750), [#751](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/751), [#757](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/757), [#765](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/765), [#777](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/777), [#785](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/785), [#789](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/789), and [#829](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/829)
* Improved handling of "simple" projects (BwX with no generated files): [#743](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/743)
* Most Bazel generated files are no longer copied into Derived Data: [#744](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/744), [#749](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/749), [#752](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/752), [#754](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/754), [#760](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/760), [#761](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/761), [#768](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/768), [#767](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/767), [#771](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/771), [#773](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/773), [#775](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/775), [#780](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/780)
* Improved handling of automatic unfocused targets (i.e. "Xcode unsupported" targets): [#753](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/753), [#824](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/824), and [#830](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/830)
* Fixed errors when using `--incompatible_enable_cc_toolchain_resolution`: [#756](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/756)
* Fixed launching of tests with test hosts with custom `executable_name`: [#758](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/758)
* `EXECUTABLE_EXTENSION` is now only set when it differs from the default: [#759](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/759)
* Improved handling of resources: [#769](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/769), [#788](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/788), [#814](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/814), [#883](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/883), and [#886](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/886)
* Improved handling of `Info.plist`s: [#770](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/770), [#778](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/778), and [#793](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/793)
* Improved handling of entitlements: [#774](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/774) and [#776](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/776)
* Improved third-party rule support: [#781](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/781) and [#782](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/782)
* Reduced spec.json size: [#791](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/791), [#814](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/814), [#827](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/827), [#875](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/875)
* `BazelDependency` now only generates files for the specified target: [#796](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/796), [#851](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/851), and [#862](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/862)
* Reduced amount of work done during project generation: [#797](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/797) and [#880](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/880)
* Improved formatting of generated schemes to better match what Xcode expects: [#800](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/800)
* Fixed calculation of `*_DEPLOYMENT_TARGET` build settings: [#843](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/843)
* Greatly improved handling of Swift -> Objective-C debugging: [#836](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/836), [#876](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/876), [#877](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/877), [#879](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/879)
* Improved handling of `cc_binary` and `swift_binary`: [#840](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/840) and [#874](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/874)
* Moved intermediate files to `$OBJROOT`: [#860](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/860)
* Improved indexing: [#880](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/880)

<a id="0.6.0"></a>
## [0.6.0] - 2022-07-13

[0.6.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.6.0

### New

* Added support for Watch Apps: [#657](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/657), [#661](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/661), [#666](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/666), [#660](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/660), [#665](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/665), and [#718](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/718)
* Added support for App Extensions: [#689](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/689), [#687](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/687), [#699](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/699), [#701](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/701), [#720](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/720), [#634](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/634), and [#723](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/723)
* Added support for iMessage Apps: [#728](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/728), [#729](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/729)
* Added support for App Clips: [#731](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/731) and [#732](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/732)
* Added support for the `launchdplists` attribute: [#684](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/684)
* Added support for the `executable_name` attribute: [#721](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/721)

### Fixes and Improvements

* Various fixes for unmerged top-level targets: [#669](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/669), [#673](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/673), [#674](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/674), [#725](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/725), [#726](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/726)
* Improved linker flag handling: [#670](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/670)
* Removed invalid target merges warning: [#671](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/671)
* Fixed formatting of some build settings: [#717](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/717) and [#719](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/719)
* Fixed handling of `$location()/$rootpath()` in copts: [#722](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/722)
* Fixed handling of `apple_resource_bundle` in `deps`: [#734](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/734)

<a id="0.5.1"></a>
## [0.5.1] - 2022-07-06

[0.5.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.5.1

A small bug fix/improvements release:

* `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD` is now only set for iOS targets: [#635](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/635)
* Fixed `--ld-path` path processing: [#639](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/639)
* Fixed handing of targets with precompiled outputs as sources: [#644](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/644)
* Fixed some missing PCM header search paths: [#645](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/645)
* Fixed simple Build with Bazel project generation: [#650](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/650) and [#652](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/652)
* Fixed accidental inclusion of `BUILD` file in internal `bazel` folder: [#654](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/654)
* Added support for `exported_symbols_lists`: [#649](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/649) and [#655](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/655)


### Contributors

* @brentleyjones
* @BalestraPatrick
* @maxwellE
* @cgrindel
* @luispadron

### First PRs

* @luispadron made their first contribution in https://github.com/buildbuddy-io/rules_xcodeproj/pull/647

<a id="0.5.0"></a>
## [0.5.0] - 2022-07-01

[0.5.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.5.0

### New

* Unknown rules are generically handled better
    * For Bazel targets that can't be made into Xcode targets, we let Bazel build them and copy out the required outputs: [#575](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/575), [#578](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/578), [#590](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/590), [#591](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/591)
    * Bazel `features` needed by Build with Bazel are now enabled for Build with Xcode as well: [#576](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/576)
    * The Build with Bazel custom lldbinit is used when Building with Xcode as well, to enable debugging of the copied swiftmodules: [#581](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/581)
    * Various other fixes: [#558](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/558), [#598](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/598)
* Added support for the `codesignopts` attribute: [#593](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/593)
* Added support for `swift_import`: [#597](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/597)
* Added support for the `alwayslink` attribute: [#607](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/607), [#608](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/608)
* Finalized support for `apple_{dynamic,static}_{framework,xcframework}_import`: [#609](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/609), [#610](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/610), [#625](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/625), [#628](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/628)
* Added `xcodeproj.scheme_autogeneration_mode` with support for `none`, `auto`, and `all`: [#612](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/612)

### Fixes and Improvements

* Improvements to how entitlements are handled: [#546](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/546), [#547](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/547)
* Fixed flakey output group check: [#551](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/551)
* Fixed handling of `--define=apple.experimental.tree_artifact_outputs=0`: [#552](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/552)
* Fixed missing App Icons in BwX mode: [#556](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/556)
* Fixed `TestAction` scheme ordering: [#557](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/557)
* Improved resource bundle handling: [#559](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/559), [#563](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/563), [#564](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/564), [#567](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/567), [#571](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/571), [#580](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/580), [#599](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/599), [#604](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/604), [#605](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/605), [#611](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/611), [#624](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/624)
* Breakpoints set from `swiftsourceinfo` now work: [#579](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/579)
* PCM flags now match what are set by rules_swift: [#586](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/586), [#595](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/595)
* Reduced the size of the specification file passed between Bazel and `generator`: [#600](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/600), [#615](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/615), [#621](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/621)
* Improved collection of header files: [#601](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/601)
* Improved how linker flags are determined: [#602](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/602)
* Made file sorting more deterministic: [#629](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/629)

### Breaking Changes

* Adjustments to `InputFileAttributesInfo` (now named `XcodeProjAutomaticTargetProcessingInfo`)

<a id="0.4.2"></a>
## [0.4.2] - 2022-06-13

[0.4.2]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.4.2

A small bug fix/improvement release:

* Improved indexing: [#534](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/534), [#536](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/536), [#537](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/537), [#544](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/544), [#545](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/545)
* Added back the Info.plist display for Built with Bazel device builds: [#541](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/541)
* Stopped including intermediate generated files: [#542](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/542)

<a id="0.4.1"></a>
## [0.4.1] - 2022-06-10

[0.4.1]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.4.1

A small bug fix release:

* Fixed debugging before indexing bazel-out has been created: [#529](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/529)
* Fixed reinstalls of Built with Bazel apps to device: [#531](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/531)

<a id="0.4.0"></a>
## [0.4.0] - 2022-06-10

[0.4.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.4.0

### New

* Added experimental support for single targets to support both the Simulator and device destinations with the `device_and_simulator` rule: [#457](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/457), [#465](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/465), [#466](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/466), [#472](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/472), [#473](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/473), [#474](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/474), [#477](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/477), [#480](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/480), [#490](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/490), [#488](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/488), [#491](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/491), [#492](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/492), [#496](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/496), [#498](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/498), [#503](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/503), [#507](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/507), [#511](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/511), [#521](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/521) and more
* Added experimental support for improved code signing settings with the `xcode_provisioning_profile` rule: [#523](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/523) and [#525](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/525)

### Fixes and Improvements

* More file extensions are now treated as header files: [#468](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/468)
* Non-header files are now filtered out from the Compile Source phase: [#469](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/469)
* Fixed swiftmodule copying during Index Build: [#471](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/471)
* Multiplatform targets now consolidate down to a single target in Xcode: [#484](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/484), [#493](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/493)
* Improved scheme XML generation: [#486](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/486), [#494](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/494), [#495](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/495)
* Fixed a bug with `module.compilation_context` handling: [#489](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/489)
* Fixed possible output map collisions: [#500](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/500)
* Improved handling of generated files `BazelDependencies`: [#508](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/508), [#510](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/510), and [#509](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/509)
* Improved code signing support when using `local_provisioning_profile`: [#505](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/505), [#506](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/506), and [#522](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/522)
* Improved SwiftUI Previews support when Building with Bazel: [#512](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/512), [#513](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/513), [#514](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/514), [#516](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/516), [#518](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/518), [#519](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/519)
* `-g` is now filtered from PCM compilation: [#518](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/518)
* Fixed Building with Bazel in Xcode 14.0.0 Beta 1: [#520](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/520)
* Fixed running UI tests when Building with Bazel: [#526](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/526)
* `xcodeproj`'s `BUILD` files are now added to the Project navigator: [#528](https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/528)

<a id="0.3.0"></a>
## [0.3.0] - 2022-05-18

[0.3.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.3.0

### New

* Added initial support for Building with Bazel: https://github.com/buildbuddy-io/rules_xcodeproj/pull/313, https://github.com/buildbuddy-io/rules_xcodeproj/pull/316, https://github.com/buildbuddy-io/rules_xcodeproj/pull/350, https://github.com/buildbuddy-io/rules_xcodeproj/pull/359, https://github.com/buildbuddy-io/rules_xcodeproj/pull/362, https://github.com/buildbuddy-io/rules_xcodeproj/pull/384, https://github.com/buildbuddy-io/rules_xcodeproj/pull/389, https://github.com/buildbuddy-io/rules_xcodeproj/pull/394, https://github.com/buildbuddy-io/rules_xcodeproj/pull/396, https://github.com/buildbuddy-io/rules_xcodeproj/pull/401, https://github.com/buildbuddy-io/rules_xcodeproj/pull/404, https://github.com/buildbuddy-io/rules_xcodeproj/pull/405, https://github.com/buildbuddy-io/rules_xcodeproj/pull/408, https://github.com/buildbuddy-io/rules_xcodeproj/pull/407, https://github.com/buildbuddy-io/rules_xcodeproj/pull/420, https://github.com/buildbuddy-io/rules_xcodeproj/pull/422, https://github.com/buildbuddy-io/rules_xcodeproj/pull/423, https://github.com/buildbuddy-io/rules_xcodeproj/pull/425, https://github.com/buildbuddy-io/rules_xcodeproj/pull/426, https://github.com/buildbuddy-io/rules_xcodeproj/pull/440, https://github.com/buildbuddy-io/rules_xcodeproj/pull/446, and more
  * ⚠️ Support for Building with Bazel is still very rough, and has a bit more to go in order to reach our [high level goals](https://github.com/buildbuddy-io/rules_xcodeproj/blob/0.3.0/doc/design/high-level.md). Also, in Bazel versions that still have [this bug](https://github.com/bazelbuild/bazel/issues/13997), the rapidly changing nature of the support (which will involve more transitions changes) can make it annoying to use this mode. _With that said_, we would appreciate all the feedback we can get from early testers! :warning:
* Added support for `cc_library.includes`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/310  and https://github.com/buildbuddy-io/rules_xcodeproj/pull/325
* Added support for `swift_library.private_deps`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/342
* Added support for `objc_import`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/347
* Schemes are now generated instead of letting Xcode generate them: https://github.com/buildbuddy-io/rules_xcodeproj/pull/361, https://github.com/buildbuddy-io/rules_xcodeproj/pull/397, and https://github.com/buildbuddy-io/rules_xcodeproj/pull/385
* Added support for code signing entitlements: https://github.com/buildbuddy-io/rules_xcodeproj/pull/367
* Added support for `objc_library.sdk_dylibs`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/372
* Added support for Core Data model files: https://github.com/buildbuddy-io/rules_xcodeproj/pull/288

### Fixes and Improvements

* Fixed explosive memory use of inefficient `_process_dependencies()`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/307
* Fixed projects failing to build after being moved: https://github.com/buildbuddy-io/rules_xcodeproj/pull/319
* Improved indexing: https://github.com/buildbuddy-io/rules_xcodeproj/pull/329 and https://github.com/buildbuddy-io/rules_xcodeproj/pull/330
* Improved handling of projects without Bazel generated files: https://github.com/buildbuddy-io/rules_xcodeproj/pull/331, https://github.com/buildbuddy-io/rules_xcodeproj/pull/332, https://github.com/buildbuddy-io/rules_xcodeproj/pull/337, and  https://github.com/buildbuddy-io/rules_xcodeproj/pull/381
* Improved handling of Bazel outputs: https://github.com/buildbuddy-io/rules_xcodeproj/pull/333, https://github.com/buildbuddy-io/rules_xcodeproj/pull/353, https://github.com/buildbuddy-io/rules_xcodeproj/pull/430, https://github.com/buildbuddy-io/rules_xcodeproj/pull/431, and https://github.com/buildbuddy-io/rules_xcodeproj/pull/434
* Various linking improvements: https://github.com/buildbuddy-io/rules_xcodeproj/pull/340, https://github.com/buildbuddy-io/rules_xcodeproj/pull/345, https://github.com/buildbuddy-io/rules_xcodeproj/pull/348,  https://github.com/buildbuddy-io/rules_xcodeproj/pull/365, https://github.com/buildbuddy-io/rules_xcodeproj/pull/409
* Improved handling of frameworks: https://github.com/buildbuddy-io/rules_xcodeproj/pull/346 and https://github.com/buildbuddy-io/rules_xcodeproj/pull/444
* Objective-C is now used instead of Swift for the compile stub: https://github.com/buildbuddy-io/rules_xcodeproj/pull/369
* A work around for an Xcode debugging crash related to `DYLD_LIBRARY_PATH` is now used: https://github.com/buildbuddy-io/rules_xcodeproj/pull/373
* Various changes to ensure that `--incompatible_disallow_empty_glob` is supported
* Removed color ansi codes from bazel output within Xcode: https://github.com/buildbuddy-io/rules_xcodeproj/pull/410
* Info.plist patching warning is now silenced: https://github.com/buildbuddy-io/rules_xcodeproj/pull/411
* `dbg` compilation mode is used when building insides Xcode: https://github.com/buildbuddy-io/rules_xcodeproj/pull/413
* Fixed default `GCC_OPTIMIZATION_LEVEL`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/412
* Fixed `-debug-prefix-map` handling: https://github.com/buildbuddy-io/rules_xcodeproj/pull/416
* Improved disambiguation of targets with names that only differ by case: https://github.com/buildbuddy-io/rules_xcodeproj/pull/424
* Improved filtering of input files: https://github.com/buildbuddy-io/rules_xcodeproj/pull/442

<a id="0.2.0"></a>
## [0.2.0] - 2022-04-15

[0.2.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.2.0

### New

* Added support for `macos_unit_test`,`tvos_unit_test`, and `watchos_unit_test`:  https://github.com/buildbuddy-io/rules_xcodeproj/pull/267, https://github.com/buildbuddy-io/rules_xcodeproj/pull/282, and https://github.com/buildbuddy-io/rules_xcodeproj/pull/286
* Added support for `-application-extension`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/287
* Added support for the `pch` attribute: https://github.com/buildbuddy-io/rules_xcodeproj/pull/280
* `BUILD` files are now included in Xcode's Project navigator: https://github.com/buildbuddy-io/rules_xcodeproj/pull/301

### Fixes and Improvements

* Fixed build errors when no targets produced `modulemap` files: https://github.com/buildbuddy-io/rules_xcodeproj/pull/251
* The `ARCHS` build setting is now set: https://github.com/buildbuddy-io/rules_xcodeproj/pull/249
* Fixed `PRODUCT_MODULE_NAME` calculation: https://github.com/buildbuddy-io/rules_xcodeproj/pull/253
* Fixed `UIDeviceFamily` Info.plist warning: https://github.com/buildbuddy-io/rules_xcodeproj/pull/260
* Fixed various framework linking issues: https://github.com/buildbuddy-io/rules_xcodeproj/pull/259, https://github.com/buildbuddy-io/rules_xcodeproj/pull/258, https://github.com/buildbuddy-io/rules_xcodeproj/pull/277, and https://github.com/buildbuddy-io/rules_xcodeproj/pull/278
* Converted last use of `python` to `python3`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/254
* Fixed file permissions of copied generated files: https://github.com/buildbuddy-io/rules_xcodeproj/pull/255
* We now list sources in the same order that Bazel sees them: https://github.com/buildbuddy-io/rules_xcodeproj/pull/265
* Fixed function name typo in warning message: https://github.com/buildbuddy-io/rules_xcodeproj/pull/274
* Fixed PCM compilation by setting `GCC_PREPROCESSOR_DEFINITIONS` instead of `OTHER_CFLAGS`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/275
* Fixed modulemap rewriting: https://github.com/buildbuddy-io/rules_xcodeproj/pull/279 and https://github.com/buildbuddy-io/rules_xcodeproj/pull/284
* Improved `defines` and `local_defines` detection: https://github.com/buildbuddy-io/rules_xcodeproj/pull/276
* Fixed resource collection for targets that are included via `deps`: https://github.com/buildbuddy-io/rules_xcodeproj/pull/263
* The `SUPPORTED_PLATFORMS` build setting is now set: https://github.com/buildbuddy-io/rules_xcodeproj/pull/289
* Fixed Swift `copt` set PCM header search paths: https://github.com/buildbuddy-io/rules_xcodeproj/pull/291
* Improved Indexing: https://github.com/buildbuddy-io/rules_xcodeproj/pull/292 and https://github.com/buildbuddy-io/rules_xcodeproj/pull/294
* Improved initial project generation experience: https://github.com/buildbuddy-io/rules_xcodeproj/pull/297 and https://github.com/buildbuddy-io/rules_xcodeproj/pull/298

<a id="0.1.0"></a>
## [0.1.0] - 2022-04-05

[0.1.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/releases/tag/0.1.0

Initial release.
