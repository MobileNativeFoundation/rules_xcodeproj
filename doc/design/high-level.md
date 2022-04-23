# High Level Design

rules_xcodeproj has a few high level design goals:

- Only the `xcodeproj` rule is necessary to create a working project
- The project can be further customized by using additional rules_xcodeproj
  rules, or by returning certain rules_xcodeproj providers from custom rules
- Outputs are as similar to `bazel build` as possible
- The project feels as "native" in Xcode as possible
- All definition of a project exists in `BUILD` files
- The project can be configured to use either Xcode or Bazel as the build system

It's also worth mentioning a few non-goals of rules_xcodeproj:

- Providing additional non-`xcodeproj` related build rules
- Changing the way a target builds in order to enable Xcode features

## Only the `xcodeproj` rule is necessary

If all one does is define an `xcodeproj` target, then the resulting project
should build and run. There should be no need to adjust the way your workspace
is built in any way, or define any additional intermediary targets.

Bazel allows for some pretty complicated stuff, and not all of it will
automatically translate neatly into Xcode's world. In those cases the project
should still build and run (see how in the [build mode](#multiple-build-modes)
section), but the project might not be in an ideal state (e.g. schemes might not
be the way you want them, or custom rule targets might not be represented
ideally). This can be addressed through project customization.

## Projects can be customized

As mentioned above, the default state of using just the `xcodeproj` rule might
result in a project that isn't "ideal". While the project should be able to
build and run without doing anything else, rules_xcodeproj will support project
customization through the use of additional rules and providers.

### Additional rules

At the bare minimum, the `xcodeproj` rule depends on the targets that you want
represented in the project. This will generate a project that allows you to
build, and if applicable run, those targets. If possible, all of the transitive
dependencies will also individually be buildable and runnable. Default schemes
will be created for each of these Xcode targets.

What if you don't like the way the schemes are created (e.g. too many, with
incorrect options, or not enough targets per scheme)? Or what if you don't want
all of the transitive dependencies represented in Xcode? Or what if you want to
customize how a target is represented, maybe by adding additional Xcode build
settings (e.g. to support
[XCRemoteCache](https://github.com/spotify/XCRemoteCache)) or Run Script build
phases (e.g. to add IDE only linting)?

These scenarios will be handled by additional rules that `xcodeproj` can depend
on to customize your project. The key characteristic of these rules is it gives
the project generator control over how their project is setup. This is in
contrast to the other customization point, providers.

### Providers

The core of the `xcodeproj` rule is the `xcodeproj_aspect` aspect, which
traverses the dependency graph of the targets passed to an `xcodeproj` instance.
The aspect collects information from providers of other rules (i.e.
[`CcInfo`](https://bazel.build/rules/lib/CcInfo),
[`SwiftInfo`](https://github.com/bazelbuild/rules_swift/blob/master/doc/providers.md#swiftinfo),
and various rules_apple providers), as well as information from rules_xcodeproj
providers that it creates. The rule then uses that information to shape the
project that it generates.

The `xcodeproj` rule has to make some assumptions about the data it gets, as the
providers from other rules don't have the fidelity needed to perfectly recreate
a similar Xcode target. rules_xcodeproj will expose providers and associated
helper functions, to allow rules, including your own custom ones, to control how
the `xcodeproj` generates targets. The goal being that a default,
non-customized, project is as natural as possible. Rules that return
rules_xcodeproj providers can choose to expose customization points, similar to
the additional rules mentioned above, but that's not their primary purpose.

## Attempts to match the outputs of `bazel build`

By virtue of the [first goal](#only-the-xcodeproj-rule-is-necessary), most
Xcode outputs will match those produced by `bazel build`. There are other areas
though, e.g. dealing with hermeticity, debugging, and indexing, where additional
care will need to be taken.

## Native feeling projects

Ideally, you shouldn't be able to tell that a project was generated with
rules_xcodeproj. It should look and feel like any other Xcode project. This
should also be the case regardless of which [build mode](#multiple-build-modes)
is used.

When that isn't the case, and there needs to be a deviation (mainly to [satisfy
other constraints](#attempts-to-match-the-outputs-of-bazel-build)), then the
generated project should deviate as little as possible. A [different build
mode](#build-with-bazel-via-proxy) might be required to make the project feel
more native.

## Defined in `BUILD` files

The building blocks of a rules_xcodeproj project generation is the `xcodeproj`
rule and associated [customization rules](#additional-rules). Targets using
these rules are defined in `BUILD` files, and generating a project happens by
executing  `bazel run` on an `xcodeproj` target. There is no need to create
additional configuration files, or to run additional commands.

Some setups might require something more dynamic, in particular when using the
focused project customization. For these cases the recommended approach, which
we might supply some optional tools for, is to dynamically generate `.bzl` files
with macros that create the required targets and use those in your `BUILD`
files.

## Multiple build modes

The `xcodeproj` rule will allow specifying a build mode that should be used by
the generated project. This will allow the project to build with Xcode instead
of Bazel, if that is desired.

Here are a few reasons one may want to build with
Xcode instead of Bazel:

- If a new, possibly beta, version of Xcode is released with a feature that
  Build with Bazel doesn't support yet, because one of Bazel, rules_apple,
  rules_swift, or rules_xcodeproj doesn't support it
- To work around a bug in Bazel, rules_apple, rules_swift, or rules_xcodeproj
- To compare the Bazel and Xcode build systems or build commands
- As a step when migrating to Bazel

### Build with Xcode

In the "Build with Xcode" mode, the generated project will let Xcode orchestrate
the build. Xcode Build Settings, target dependencies, etc. are all set up to
create a normal Xcode experience.

To ensure that the resulting build is as similar to a Bazel build as
possible, some things are done differently than a vanilla Xcode project. In
particular, `BUILT_PRODUCTS_DIR` is set to a nested folder, mirroring the layout
of `bazel-out/`, and various search paths are adjusted to account for this.

There are also aspects of a Bazel build that can't be neatly translated into an
Xcode concept (though updating rules to supply [rules_xcodeproj
providers](#providers) can help). One that will come up in nearly every project
is code generation. In these situations the project takes on a hybrid approach,
invoking `bazel build` for a portion of the build. The degree to which `bazel
build` needs to handle the build depends on the the rules involved.

Of note, projects can be customized to force more of the build to be hybrid,
through the use of [focused project rules](#additional-rules).

### Build with Bazel

In the "Build with Bazel" mode, the generated project will invoke `bazel build`
to perform the actual build, as a root or detached dependency, and then stub
out the build actions that Xcode tries to perform. A version of this method is
detailed [here](https://github.com/kastiglione/bazel-xcode-demo-swift-driver/tree/master/bazel#disabling-xcodes-build)
and [here](https://www.youtube.com/watch?t=1301&v=NAPeWoimGx8).

In addition to the stubbing, targets will have their serialized diagnostics
replayed, resulting in fully functional warnings and fix-its, that stick around
between builds, but also clear when they are supposed to.

This will be the default build mode by the 1.0 release.

### Build with Bazel via Proxy

rules_xcodeproj will support one more build mode called "Build with Bazel via
Proxy". In this mode the generated project will rely on Xcode using an
[XCBBuildServiceProxy](https://github.com/target/XCBBuildServiceProxy). This
takes the Xcode build system entirely out of the equation, allowing Bazel to
fully control the build.

Here are some benefits that the proxy provides over "Build with Bazel":

- No additional "Bazel Dependencies" target in the build graph
- Removal of duplicate warnings/errors
- More stable Indexing
- User created schemes (without defining bazel rules to create them) work as
  expected
- Fully functional progress bar (though there is hope that we can get it to
  partially work with "Build with Bazel")
- Less overhead

With all of these benefits, you may be wondering why "Build with Bazel" will be
the default build mode instead of "Build with Bazel via Proxy". There are two
main reasons:

- The proxy relies on a private API that Xcode uses to communicate with
  XCBBuildService. This can have, and has had, breaking changes between Xcode
  versions.
- To have Xcode use the proxy, you either need to launch it with an environment
  variable (via `launchctl setenv` once per boot, `/etc/launchd.conf`
  permanently, or `env VAR=X open -a Xcode.app`), or slightly modify the Xcode
  app bundle. If using the global environment variable approach (as opposed to
  `open -a` or a modified bundle), all Xcode versions that are launched will use
  the same proxy. While the proxy will be written to only build with Bazel for
  projects generated with rules_xcodeproj, the proxy might be tied to a specific
  version of Xcode and not work with other versions.

For some teams the benefits outweigh these inconveniences, and there will always
be the "Build with Bazel" fallback mode in case something goes wrong.

## No additional non-`xcodeproj` related build rules

rules_xcodeproj won't provide additional non-`xcodeproj` related build rules.
That is to say, the only rules that will be provided are `xcodeproj` and rules
that interact directly with `xcodeproj`. These rules won't modify your build
graph.

To put it yet another way, rules_xcodeproj won't provide rules that make your
`bazel build` more like Xcode (which is one reason it wasn't named
"rules_xcode"). Those sorts of rules will have to come from other rulesets.

## Won't change the way a target builds in order to enable Xcode features

This non-goal stems from restrictions that SwiftUI previews have, in particular
that they aren't supported with static libraries. rules_xcodeproj won't change
the product type of your target to enable SwiftUI previews; doing so would get
in the way of [previous goals](#attempts-to-match-the-outputs-of-bazel-build).
We will provide guidance on how to change your build yourself and integrate that
change with rules_xcodeproj, but the rules themselves won't make those changes
for you.
