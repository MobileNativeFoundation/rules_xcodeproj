This is a branch for investigating why SwiftUI Previews have stopped working in Xcode 16, I would love for people to come with inputs and contribute so we can solve this together

# Generating example project

This folder contains a project.yml file that will generate the project when running 'xcodegen generate' 

If xcodegen isn't installed, please visit https://github.com/yonaskolb/XcodeGen#installing and follow the instructions

# How to get Bazel flags
cd to rules_xcodeproj root and run:
bazelisk build tools/swiftc_stub:universal_swiftc_stub

This will create a bunch of files in 
/Users/User/Downloads/rules_xcodeproj/bazel-output-base/execroot/_main/bazel-out/darwin_x86_64-fastbuild-macos-x86_64-min12.0-applebin_macos-ST-50cbb438abaf/bin/tools 

Find the files called “swiftc_stub_binary-2.params” and "swiftc-stub.swiftmodue-0"

Open with TextEdit.

# How to get extended Build log

Open Xcode and go to Target -> Build Phases -> New Run Script Phase

Paste “echo $CFLAGS”

Run the app

Navigate to "Report navigator"

Go to the Build section and press “Export” in the top right corner.

This file will contains C-flags settings in Xcode

# wrapped_clang_params: WIP
