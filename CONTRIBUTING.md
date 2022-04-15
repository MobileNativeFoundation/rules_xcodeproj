## Pull Requests

All changes, no matter how trivial, must be done via pull request. Commits
should never be made directly on the `main` branch. Prefer rebasing over
merging `main` into your PR branch to update it and resolve conflicts.

## Building And Running Locally

1. `git clone https://github.com/buildbuddy-io/rules_xcodeproj.git`
1. `cd rules_xcodeproj`
1. `bazel run //tools/generator:xcodeproj` to generate an Xcode project
and develop in Xcode, or just open the directory in your favourite text
editor.
1. Build with Xcode: 
    1. Select the `generator` scheme to compile the executable.
    1. Select the `tests` scheme to run the tests.
1. Build with Bazel: 
    1. `bazel build //tools/generator` to compile the executable.
    1. `bazel test //test/...` to run the tests.

## Developing

Feel free to volunteer by picking up any bug from the list of
[GitHub issues](https://github.com/buildbuddy-io/rules_xcodeproj/issues).
If you find a new bug or would like to work on a new feature,
create a new GitHub issue to better describe your intentions. We are happy
to guide contributors with an implementation through discussions if needed.

You can test your changes in the example projects by generating their 
projects with `bazel run //examples/cc:xcodeproj`. You might need to `cd`
into the directory if the example app is in a separate `WORKSPACE` with
`cd examples/ios_app; bazel run //:xcodeproj`.

You can even test your changes in a separate project living outside this repo with
`bazel run //:your_xcodeproj --override_repository=com_github_buildbuddy_io_rules_xcodeproj=/Users/username/rules_xcodeproj`

While developing, you might need to regenerate the test fixtures.
You can do so with 
`bazel run --config=cache //test/fixtures:update --verbose_failures; cd examples/ios_app/; bazel run --config=cache //test/fixtures:update --verbose_failures;`
