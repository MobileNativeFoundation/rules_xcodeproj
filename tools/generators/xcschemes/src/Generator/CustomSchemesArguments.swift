import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

struct CustomSchemesArguments: ParsableArguments {
    @Option(
        parsing: .upToNextOption,
        help: "Name for all of the custom schemes."
    )
    var customSchemes: [String] = []

    // MARK: Test

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Test build-only targets per custom scheme. For example, \
'--test-build-only-target-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two build-only targets \
from <test-build-only-targets>, and the second custom scheme should include \
the next three build-only targets. There must be exactly as many build-only \
target counts as there are custom schemes, or no build-only target counts if \
there are no Test build-only targets among all of the schemes. The sum of all \
of the build-only target counts must equal the number of \
<test-build-only-targets> elements.
"""
    )
    var testBuildOnlyTargetCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Test action build-only targets for all of the custom schemes. See \
<test-build-only-target-counts> for how these build-only targets be \
distributed between the custom schemes.
"""
    )
    var testBuildOnlyTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Test action command-line arguments per custom scheme. For example, \
'--test-command-line-argument-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two \
command-line arguments from <test-command-line-arguments>, and the second \
custom scheme should include the next three command-line arguments. There must \
be exactly as many command-line argument counts as there are custom schemes, \
or no command-line argument counts if there are no Test action command-line \
arguments among all of the schemes. The sum of all of the command-line \
argument counts must equal the number of <test-command-line-arguments> elements.
"""
    )
    var testCommandLineArgumentCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Test action command-line arguments for all of the custom schemes. See \
<test-command-line-argument-counts> for how these command-line arguments will \
be distributed between the custom schemes.
"""
    )
    var testCommandLineArguments: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has Address Sanitizer enabled for the test action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var testEnableAddressSanitizer: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has Thread Sanitizer enabled for the test action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var testEnableThreadSanitizer: [Bool] = []

    @Option(
        name: .customLong("test-enable-ub-sanitizer"),
        parsing: .upToNextOption,
        help: """
If the scheme has UB Sanitizer enabled for the Test action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var testEnableUBSanitizer: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Test action environment variables per custom scheme. For example, \
'--test-environment-variable-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two environment \
variable pairs from <test-environment-variables>, and the second custom scheme \
should include the next three environment variable pairs. There must be \
exactly as many environment variable counts as there are custom schemes, or no \
environment variable counts if there are no Test action environment variables \
among all of the schemes. The sum of all of the environment variable counts \
must equal half the number of <test-environment-variables> elements.
"""
    )
    var testEnvironmentVariableCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Test action environment variables for all of the custom schemes. Must be \
specified as <key> <value> pairs. See <test-environment-variable-counts> for \
how these environment variables will be distributed between the custom schemes.
"""
    )
    var testEnvironmentVariables: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of test targets per custom scheme. For example, \
'--test-target-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two test targets from \
<test-targets>, and the second custom scheme should include the next three \
test targets. There must be exactly as many test target counts as there are \
custom schemes, or no test target counts if there are no test targets among \
all of the schemes. The sum of all of the test target counts must equal the \
number of <test-targets> elements.
"""
    )
    var testTargetCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Test targets for all of the custom schemes. See <test-target-counts> for how \
these test targets be distributed between the custom schemes.
"""
    )
    var testTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the Test action should use the Run action's command-line arguments and \
environment variables. There must be exactly as many bools as there are custom \
schemes.
""",
        transform: { $0 == "1" }
    )
    var testUseRunArgsAndEnv: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The Xcode configuration to use for the Test action. There must be exactly as \
many Test action Xcode configurations as there are custom schemes. If an empty \
string, the Test action will use whatever Xcode configuration is chosen for \
the Test action. See <run-xcode-configuration> for more details.
"""
    )
    var testXcodeConfiguration: [String?] = []

    // MARK: Run

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Run build-only targets per custom scheme. For example, \
'--run-build-only-target-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two build-only targets \
from <run-build-only-targets>, and the second custom scheme should include the \
next three build-only targets. There must be exactly as many build-only target \
counts as there are custom schemes, or no build-only target counts if there \
are no Run build-only targets among all of the schemes. The sum of all of the \
build-only target counts must equal the number of <run-build-only-targets> \
elements.
"""
    )
    var runBuildOnlyTargetCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Run action build-only targets for all of the custom schemes. See \
<run-build-only-target-counts> for how these build-only targets be distributed \
between the custom schemes.
"""
    )
    var runBuildOnlyTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Run action command-line arguments per custom scheme. For example, \
'--run-command-line-argument-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two \
command-line arguments from <run-command-line-arguments>, and the second \
custom scheme should include the next three command-line arguments. There must \
be exactly as many command-line argument counts as there are custom schemes, \
or no command-line argument counts if there are no Run action command-line \
arguments among all of the schemes. The sum of all of the command-line \
argument counts must equal the number of <run-command-line-arguments> elements.
"""
    )
    var runCommandLineArgumentCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Run action command-line arguments for all of the custom schemes. See \
<run-command-line-argument-counts> for how these command-line arguments will \
be distributed between the custom schemes.
"""
    )
    var runCommandLineArguments: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The custom working directory for the Run action. There must be exactly as many \
custom working directories as there are custom schemes. If the Run action \
doesn't have a custom working directory, use an empty string.
"""
    )
    var runCustomWorkingDirectory: [String?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has Address Sanitizer enabled for the Run action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var runEnableAddressSanitizer: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has Thread sanitizer enabled for the Run action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var runEnableThreadSanitizer: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Run action environment variables per custom scheme. For example, \
'--run-environment-variable-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two environment \
variable pairs from <run-environment-variables>, and the second custom scheme \
should include the next three environment variable pairs. There must be \
exactly as many environment variable counts as there are custom schemes, or no \
environment variable counts if there are no Run action environment variables \
among all of the schemes. The sum of all of the environment variable counts \
must equal half the number of <run-environment-variables> elements.
"""
    )
    var runEnvironmentVariableCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Run action environment variables for all of the custom schemes. Must be \
specified as <key> <value> pairs. See <run-environment-variable-counts> for \
how these environment variables will be distributed between the custom schemes.
"""
    )
    var runEnvironmentVariables: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has UB Sanitizer enabled for the Run action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var runEnableUBSanitizer: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID of the extension host to use to launch <run-launch-target>. If \
the Run launch target isn't an application extension, use an empty string. If \
this isn't an empty string, <run-launch-target> must also not be an empty \
string.
"""
    )
    var runLaunchExtensionHost: [TargetID?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID of the target to launch with the Run action. If the Run action \
doesn't have a launch target, use an empty string. There must be exactly as \
many Run launch targets as there are custom schemes.
"""
    )
    var runLaunchTarget: [TargetID?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The Xcode configuration to use for the Run action. There must be exactly as \
many Run action Xcode configurations as there are custom schemes. If the Run \
action should use the default Xcode configuration, use an empty string.
"""
    )
    var runXcodeConfiguration: [String?] = []

    // MARK: Profile

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Profile build-only targets per custom scheme. For example, \
'--profile-build-only-target-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two build-only targets \
from <profile-build-only-targets>, and the second custom scheme should include \
the next three build-only targets. There must be exactly as many build-only \
target counts as there are custom schemes, or no build-only target counts if \
there are no Profile build-only targets among all of the schemes. The sum of \
all of the build-only target counts must equal the number of \
<profile-build-only-targets> elements.
"""
    )
    var profileBuildOnlyTargetCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Profile action build-only targets for all of the custom schemes. See \
<profile-build-only-target-counts> for how these build-only targets be \
distributed between the custom schemes.
"""
    )
    var profileBuildOnlyTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Profile action command-line arguments per custom scheme. For \
example, '--profile-command-line-argument-counts 2 3' means the first custom \
scheme (as specified by <custom-schemes>) should include the first two \
command-line arguments from <profile-command-line-arguments>, and the second \
custom scheme should include the next three command-line arguments. There must \
be exactly as many command-line argument counts as there are custom schemes, \
or no command-line argument counts if there are no Profile action command-line \
arguments among all of the schemes. The sum of all of the command-line \
argument counts must equal the number of <profile-command-line-arguments> \
elements.
"""
    )
    var profileCommandLineArgumentCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Profile action command-line arguments for all of the custom schemes. See \
<profile-command-line-argument-counts> for how these command-line arguments \
will be distributed between the custom schemes.
"""
    )
    var profileCommandLineArguments: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The custom working directory for the Profile action. There must be exactly as \
many custom working directories as there are custom schemes. If the Profile \
action doesn't have a custom working directory, use an empty string.
"""
    )
    var profileCustomWorkingDirectory: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Profile action environment variables per custom scheme. For example, \
'--profile-environment-variable-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two environment \
variable pairs from <run-environment-variables>, and the second custom scheme \
should include the next three environment variable pairs. There must be \
exactly as many environment variable counts as there are custom schemes, or no \
environment variable counts if there are no Profile action environment \
variables among all of the schemes. The sum of all of the environment variable \
counts must equal half the number of <profile-environment-variables> \
elements.
"""
    )
    var profileEnvironmentVariableCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Profile action environment variables for all of the custom schemes. Must be \
specified as <key> <value> pairs. See <profile-environment-variable-counts> \
for how these environment variables will be distributed between the custom \
schemes.
"""
    )
    var profileEnvironmentVariables: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID of the extension host to use to launch <profile-launch-target>. \
If the Profile launch target isn't an application extension, use an empty \
string. If this isn't an empty string, <profile-launch-target> must also not
be an empty string.
"""
    )
    var profileLaunchExtensionHost: [TargetID?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID of the target to launch with the Profile action. If the Profile \
action doesn't have a launch target, use an empty string. There must be \
exactly as many Profile launch targets as there are custom schemes.
"""
    )
    var profileLaunchTarget: [TargetID?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the Profile action should use the Run action's command-line arguments and \
environment variables. There must be exactly as many bools as there are custom \
schemes.
""",
        transform: { $0 == "1" }
    )
    var profileUseRunArgsAndEnv: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The Xcode configuration to use for the Profile action. There must be exactly \
as many Profile action Xcode configurations as there are custom schemes. If \
an empty string, the Profile action will use whatever Xcode configuration is
chosen for the Run action. See <run-xcode-configuration> for more details.
"""
    )
    var profileXcodeConfiguration: [String?] = []

    // MARK: Execution actions

    @OptionGroup var executionActionsArguments: ExecutionActionsArguments

    // MARK: Validation

    mutating func validate() throws {

        // MARK: Test

        let testBuildOnlyTargetCountsSum =
            testBuildOnlyTargetCounts.reduce(0, +)
        guard testBuildOnlyTargetCountsSum == testBuildOnlyTargets.count else {
            throw ValidationError("""
The sum of <test-build-only-target-counts> (\(testBuildOnlyTargetCountsSum)) \
must equal the number of <test-build-only-targets> elements \
(\(testBuildOnlyTargets.count)).
""")
        }

        guard testBuildOnlyTargetCountsSum == 0 ||
                testBuildOnlyTargetCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<test-build-only-target-counts> (\(testBuildOnlyTargetCounts.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        let testCommandLineArgumentCountsSum =
            testCommandLineArgumentCounts.reduce(0, +)
        guard testCommandLineArgumentCountsSum ==
                testCommandLineArguments.count
        else {
            throw ValidationError("""
The sum of <test-command-line-argument-counts> \
(\(testCommandLineArgumentCountsSum)) must equal the number of \
<test-command-line-arguments> elements (\(testCommandLineArguments.count)).
""")
        }

        guard testCommandLineArgumentCountsSum == 0 ||
                testCommandLineArgumentCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<test-command-line-argument-counts> (\(testCommandLineArgumentCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard testEnableAddressSanitizer.count == customSchemes.count else {
            throw ValidationError("""
<test-enable-address-sanitizer> (\(testEnableAddressSanitizer.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard testEnableThreadSanitizer.count == customSchemes.count else {
            throw ValidationError("""
<test-enable-thread-sanitizer> (\(testEnableThreadSanitizer.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard testEnableUBSanitizer.count == customSchemes.count else {
            throw ValidationError("""
<test-enable-ub-sanitizer> (\(testEnableUBSanitizer.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        let testEnvironmentVariableCountsSum =
            testEnvironmentVariableCounts.reduce(0, +)
        guard testEnvironmentVariableCountsSum * 2 ==
                testEnvironmentVariables.count
        else {
            throw ValidationError("""
The sum of <test-environment-variables-counts> \
(\(testEnvironmentVariableCountsSum)) must equal half the number of \
<test-command-line-arguments> elements (\(testEnvironmentVariables.count)).
""")
        }

        guard testEnvironmentVariableCountsSum == 0 ||
                testEnvironmentVariableCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<test-environment-variable-counts> (\(testEnvironmentVariableCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard testEnvironmentVariables.count.isMultiple(of: 2) else {
            throw ValidationError("""
<test-environment-variable> must be <key> <value> pairs.
""")
        }

        let testTargetCountsSum = testTargetCounts.reduce(0, +)
        guard testTargetCountsSum == testTargets.count else {
            throw ValidationError("""
The sum of <test-target-counts> (\(testTargetCountsSum)) must equal the number \
of <test-targets> elements (\(testTargets.count)).
""")
        }

        guard testTargetCountsSum == 0 ||
                testTargetCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<test-target-counts> (\(testTargetCounts.count) elements) must have exactly as \
many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard testUseRunArgsAndEnv.count == customSchemes.count else {
            throw ValidationError("""
<test-use-run-args-and-env> (\(testUseRunArgsAndEnv.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard testUseRunArgsAndEnv.count == customSchemes.count else {
            throw ValidationError("""
<test-use-run-args-and-env> (\(testUseRunArgsAndEnv.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard testXcodeConfiguration.count == customSchemes.count else {
            throw ValidationError("""
<test-xcode-configuration> (\(testXcodeConfiguration.count) elements) must \
have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        // MARK: Run

        let runBuildOnlyTargetCountsSum =
            runBuildOnlyTargetCounts.reduce(0, +)
        guard runBuildOnlyTargetCountsSum == runBuildOnlyTargets.count else {
            throw ValidationError("""
The sum of <run-build-only-target-counts> (\(runBuildOnlyTargetCountsSum)) \
must equal the number of <run-build-only-targets> elements \
(\(runBuildOnlyTargets.count)).
""")
        }

        guard runBuildOnlyTargetCountsSum == 0 ||
                runBuildOnlyTargetCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<run-build-only-target-counts> (\(runBuildOnlyTargetCounts.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        let runCommandLineArgumentCountsSum =
            runCommandLineArgumentCounts.reduce(0, +)
        guard runCommandLineArgumentCountsSum ==
                runCommandLineArguments.count
        else {
            throw ValidationError("""
The sum of <run-command-line-argument-counts> \
(\(runCommandLineArgumentCountsSum)) must equal the number of \
<run-command-line-arguments> elements (\(runCommandLineArguments.count)).
""")
        }

        guard runCommandLineArgumentCountsSum == 0 ||
                runCommandLineArgumentCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<run-command-line-argument-counts> (\(runCommandLineArgumentCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard runCustomWorkingDirectory.count == customSchemes.count else {
            throw ValidationError("""
<run-custom-working-directory> (\(runCustomWorkingDirectory.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard runEnableAddressSanitizer.count == customSchemes.count else {
            throw ValidationError("""
<run-enable-address-sanitizer> (\(runEnableAddressSanitizer.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard runEnableThreadSanitizer.count == customSchemes.count else {
            throw ValidationError("""
<run-enable-thread-sanitizer> (\(runEnableThreadSanitizer.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard runEnableUBSanitizer.count == customSchemes.count else {
            throw ValidationError("""
<run-enable-ub-sanitizer> (\(runEnableUBSanitizer.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        let runEnvironmentVariableCountsSum =
            runEnvironmentVariableCounts.reduce(0, +)
        guard runEnvironmentVariableCountsSum * 2 ==
                runEnvironmentVariables.count
        else {
            throw ValidationError("""
The sum of <run-environment-variables-counts> \
(\(runEnvironmentVariableCountsSum)) must equal half the number of \
<run-command-line-arguments> elements (\(runEnvironmentVariables.count)).
""")
        }

        guard runEnvironmentVariableCountsSum == 0 ||
                runEnvironmentVariableCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<run-environment-variable-counts> (\(runEnvironmentVariableCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard runEnvironmentVariables.count.isMultiple(of: 2) else {
            throw ValidationError("""
<run-environment-variable> must be <key> <value> pairs.
""")
        }

        guard runLaunchExtensionHost.count == customSchemes.count else {
            throw ValidationError("""
<run-launch-extension-host> (\(runLaunchExtensionHost.count) elements) must \
have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard runLaunchTarget.count == customSchemes.count else {
            throw ValidationError("""
<run-launch-target> (\(runLaunchTarget.count) elements) must have exactly as \
many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard runXcodeConfiguration.count == customSchemes.count else {
            throw ValidationError("""
<run-xcode-configuration> (\(runXcodeConfiguration.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        // MARK: Profile

        let profileBuildOnlyTargetCountsSum =
            profileBuildOnlyTargetCounts.reduce(0, +)
        guard profileBuildOnlyTargetCountsSum ==
                profileBuildOnlyTargets.count
        else {
            throw ValidationError("""
The sum of <profile-build-only-target-counts> \
(\(profileBuildOnlyTargetCountsSum)) must equal the number of \
<profile-build-only-targets> elements (\(profileBuildOnlyTargets.count)).
""")
        }

        guard profileBuildOnlyTargetCountsSum == 0 ||
                profileBuildOnlyTargetCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<profile-build-only-target-counts> (\(profileBuildOnlyTargetCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        let profileCommandLineArgumentCountsSum =
            profileCommandLineArgumentCounts.reduce(0, +)
        guard profileCommandLineArgumentCountsSum ==
                profileCommandLineArguments.count
        else {
            throw ValidationError("""
The sum of <profile-command-line-argument-counts> \
(\(profileCommandLineArgumentCountsSum)) must equal the number of \
<profile-command-line-arguments> elements \
(\(profileCommandLineArguments.count)).
""")
        }

        guard profileCommandLineArgumentCountsSum == 0 ||
                profileCommandLineArgumentCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<profile-command-line-argument-counts> \
(\(profileCommandLineArgumentCounts.count) elements) must have exactly as many \
elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard profileCustomWorkingDirectory.count == customSchemes.count else {
            throw ValidationError("""
<profile-custom-working-directory> (\(profileCustomWorkingDirectory.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        let profileEnvironmentVariableCountsSum =
            profileEnvironmentVariableCounts.reduce(0, +)
        guard profileEnvironmentVariableCountsSum * 2 ==
                profileEnvironmentVariables.count
        else {
            throw ValidationError("""
The sum of <profile-environment-variables-counts> \
(\(profileEnvironmentVariableCountsSum)) must equal half the number of \
<profile-command-line-arguments> elements \
(\(profileEnvironmentVariables.count)).
""")
        }

        guard profileEnvironmentVariableCountsSum == 0 ||
                profileEnvironmentVariableCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<profile-environment-variable-counts> \
(\(profileEnvironmentVariableCounts.count) elements) must have exactly as many \
elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard profileEnvironmentVariables.count.isMultiple(of: 2) else {
            throw ValidationError("""
<profile-environment-variable> must be <key> <value> pairs.
""")
        }

        guard profileLaunchExtensionHost.count == customSchemes.count else {
            throw ValidationError("""
<profile-launch-extension-host> (\(profileLaunchExtensionHost.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard profileLaunchTarget.count == customSchemes.count else {
            throw ValidationError("""
<profile-launch-target> (\(profileLaunchTarget.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard profileUseRunArgsAndEnv.count == customSchemes.count else {
            throw ValidationError("""
<profile-use-run-args-and-env> (\(profileUseRunArgsAndEnv.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard profileXcodeConfiguration.count == customSchemes.count else {
            throw ValidationError("""
<profile-xcode-configuration> (\(profileXcodeConfiguration.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }
    }
}
