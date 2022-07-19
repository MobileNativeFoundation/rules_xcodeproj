# Frequently Asked Questions

<!--
The TOC for this document was generated using https://github.com/ekalinin/github-markdown-toc.go.

# Install gh-md-toc
brew install github-markdown-toc

# Generate TOC
gh-md-toc --hide-header --hide-footer --start-depth=1
-->
* [My Xcode project seems to be of of sync with my Bazel project\. What should I do?](#my-xcode-project-seems-to-be-of-of-sync-with-my-bazel-project-what-should-i-do)
* [When I build I get warnings like "Stale file 'PROJECT\.xcodeproj/rules\_xcodeproj/gen\_dir/\.\.\.' is located outside of the allowed root paths"\. How do I fix this?](#when-i-build-i-get-warnings-like-stale-file-projectxcodeprojrules_xcodeprojgen_dir-is-located-outside-of-the-allowed-root-paths-how-do-i-fix-this)
* [Why aren't Info\.plist details shown when Building with Bazel?](#why-arent-infoplist-details-shown-when-building-with-bazel)
* [Why do I get an error like "Provisioning profile "PROFILE\_NAME" is Xcode managed, but signing settings require a manually managed profile\. (in target 'TARGET' from project 'PROJECT')"?](#why-do-i-get-an-error-like-provisioning-profile-profile_name-is-xcode-managed-but-signing-settings-require-a-manually-managed-profile-in-target-target-from-project-project)
* [Why do I get an error like "No profile for team 'TEAM' matching 'PROFILE\_NAME' found: Xcode couldn't find any provisioning profiles matching 'TEAM\_ID/PROFILE\_NAME'\. Install the profile (by dragging and dropping it onto Xcode's dock item) or select a different one in the Signing &amp; Capabilities tab of the target editor\."?](#why-do-i-get-an-error-like-no-profile-for-team-team-matching-profile_name-found-xcode-couldnt-find-any-provisioning-profiles-matching-team_idprofile_name-install-the-profile-by-dragging-and-dropping-it-onto-xcodes-dock-item-or-select-a-different-one-in-the-signing--capabilities-tab-of-the-target-editor)
* [What is CompileStub\.m?](#what-is-compilestubm)

## My Xcode project seems to be of of sync with my Bazel project. What should I do?

The generated Xcode project includes scripts to synchronize select Bazel
generated files (e.g. `Info.plist`) with Xcode. Perform the following steps to
synchronize these file:

1. Open the Xcode project: `xed path/to/MyApp.xcodeproj`.
2. Select the `Bazel Generated Files` scheme (Menu: `Product` > `Scheme` >
   `Bazel Generated Files`).
3. Build the `Bazel Generated Files` scheme (Menu: `Product` > `Build`).
4. If items under the `Bazel Generated Files` group in the Project navigator are
   red, close and re-open the project.

All targets that depend on generates files depend on the `Bazel Generated Files`
target, so building any of those targets will also synchronize Xcode.

## When I build I get warnings like "Stale file 'PROJECT.xcodeproj/rules_xcodeproj/gen_dir/...' is located outside of the allowed root paths". How do I fix this?

This warning happens when the paths to generated files change after a project
generation. Closing and re-opening your project, or performing a clean build,
will remove the warnings.

## Why do I get an error like "Provisioning profile "PROFILE_NAME" is Xcode managed, but signing settings require a manually managed profile. (in target 'TARGET' from project 'PROJECT')"?

This error should only occur if `build_mode = "xcode"`. If you are using another
`build_mode`, please report this as a bug.

The `provisioning_profile` you have set on your top level target (i.e
`ios_application` and the like) is resolving to an Xcode managed profile. This
is common if you use the `local_provisioning_profile` rule. If this is desired,
then you need to use the `xcode_provisioning_profile` rule to tell `xcodeproj`
that this is an Xcode managed profile:

```starlark
ios_application(
   ...
   provisioning_profile = ":xcode_profile",
   ...
)

xcode_provisioning_profile(
   name = "xcode_profile",
   managed_by_xcode = True,
   provisioning_profile = ":provisioning_profile",
)
```

Also, the `:provisioning_profile` target needs to be a rule that returns the
`AppleProvisioningProfileInfo` provider, such as `local_provisioning_profile`,
and the `team_id` attribute on that provider needs to be set, or `team_id` needs
to be set on the `:xcode_profile` target.

## Why do I get an error like "No profile for team 'TEAM' matching 'PROFILE_NAME' found: Xcode couldn't find any provisioning profiles matching 'TEAM_ID/PROFILE_NAME'. Install the profile (by dragging and dropping it onto Xcode's dock item) or select a different one in the Signing & Capabilities tab of the target editor."?

This error should only occur if `build_mode = "xcode"`. If you are using another
`build_mode`, please report this as a bug.

The `provisioning_profile` you have set on your top level target (i.e
`ios_application` and the like) is resolving to a provisioning profile that
hasn't yet been installed to `~/Library/MobileDevice/Provisioning Profiles`.
This is common if you use the `local_provisioning_profile` rule and specify
fallback profiles, or if you use specify a profile in the workspace.

Copying the profile to `~/Library/MobileDevice/Provisioning Profiles` will
resolve the error.

## What is `CompileStub.m`?

If you have a top level target, such as `ios_application`, and it's primary
library dependency is also directly depended on by another top level target,
such as `ios_unit_test`, then we can't merge that library into the first top
level target. When that happens, the first top level target doesn't have any
source files, so we need to add a stub one to allow Xcode to link to the proper
library target.

If this setup isn't desired (e.g. wanting to have the target merged to enable
SwiftUI Previews), there are a couple ways to fix it. For tests, setting the
first top level target as the `test_host` will allow for the library to merge.
In other cases, refactor the build graph to have the shared code in it's own
library separate from the top level target's primary library.
