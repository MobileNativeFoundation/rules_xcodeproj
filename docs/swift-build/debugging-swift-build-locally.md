# Debugging Swift Build Locally

During the investigation into supporting Build With Proxy (BwP) for rules_xcodeproj
there will be a need to debug [swift-build](https://github.com/swiftlang/swift-build) locally.
Below are steps to help assist developers when trying to debug swift-build.

## Setup

First create a test project or find an existing project you wish to test with, copy the path
to its xcodeproj file, we will refer to this as `LOCAL_TEST_XCODEPROJ_PATH`.

```terminal
git clone git@github.com:swiftlang/swift-build.git
cd swift-build
open Package.swift
```

Once the project is opened select the `swbuild` scheme and then select `Edit Scheme`

Set `Arguments Passed on Launch` like so:

* `build`
* `LOCAL_TEST_XCODEPROJ_PATH` (using the real path of course)

Then under `Environment Variables` set the following:

* `XCBUILD_LAUNCH_IN_PROCESS=1`

## Testing

Now that that is all set up you can run the `swbuild` executable from Xcode and add breakpoints to the project. When you run this binary it is the same as if you built it using swift-build's `launch-xcode` plugin but it is in the current Xcode project.
