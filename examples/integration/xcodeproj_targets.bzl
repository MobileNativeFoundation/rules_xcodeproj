"""Exposes targets used by `xcodeproj` to allow use in fixture tests."""

load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "project_options",
    "top_level_target",
    "top_level_targets",
    "xcode_schemes",
    "xcschemes",
)

# @unsorted-dict-items
BAZEL_ENV = {
    # Inheriting any `TERM`
    "TERM": None,
    # Inheriting any `NOT_SET`, but won't find any
    "NOT_SET": None,
    # Overriding `PATH`
    "PATH": "/bin:/usr/bin:/sbin:/usr/sbin",
    # Testing escaping (quotes, spaces, newlines, and slashes)
    "QUOTES_VAR1": "foo \"bar\"",
    "QUOTES_VAR2": 'foo "bar"',
    "QUOTES_VAR3": "foo 'bar'",
    "SLASHES_VAR": "value/with\\slashes",
    "MULTILINE": """one line
two line""",
    "TRIPLE_QUOTES": "foo \"\"\"bar\"\"\"",
    # Using other environment variables
    "BASED_ON_HOME": "$HOME/.cache",
    # Escaping to not use environment variables
    "NOT_BASED_ON_HOME": "\\$HOME/.cache",
}

CONFIG = "rules_xcodeproj_integration"

PROJECT_OPTIONS = project_options(
    development_region = "es",
    indent_width = 3,
    organization_name = "BB",
    tab_width = 2,
    uses_tabs = True,
)

XCODE_CONFIGURATIONS = {
    "AppStore": {
        "//command_line_option:compilation_mode": "opt",
        "@//:flag_to_transition_on": "AAAAAAA",
    },
    "Debug": {
        "//command_line_option:compilation_mode": "dbg",
        "@//:flag_to_transition_on": "B",
    },
}

DEFAULT_XCODE_CONFIGURATION = "Debug"

PRE_BUILD = """set -euo pipefail

if [[ "$ACTION" == "build" ]]; then
  cd "$SRCROOT"
  echo "Hello from pre-build!"
fi"""

EXTRA_FILES = [
    "//:README.md",
]

FAIL_FOR_INVALID_EXTRA_FILES_TARGETS = True

ASSOCIATED_EXTRA_FILES = {
    "//Lib": ["//Lib:README.md"],
    "//Lib:ios_Lib": ["//Lib:README.md"],
    "//iOSApp/Source:iOSApp": [
        "//iOSApp:info.yaml",
        "//iOSApp:ownership.yaml",
    ],
}

UNFOCUSED_TARGETS = [
    "//Lib:LibFramework.iOS",
]

XCODEPROJ_TARGETS = [
    "//cc/tool",
    top_level_target(
        label = "//CommandLine/CommandLineTool",
        target_environments = ["device"],
    ),
    top_level_target(
        label = "//CommandLine/CommandLineTool:UniversalCommandLineTool",
        target_environments = ["device"],
    ),
    top_level_target(
        label = "//CommandLine/Tests:BasicTests",
        target_environments = ["device"],
    ),
    top_level_target(
        label = "//CommandLine/Tests:CommandLineToolTests",
        target_environments = ["device"],
    ),
    top_level_targets(
        labels = [
            "//iOSApp",
            "//Lib:ios_Lib",
            "//Lib/dist/dynamic:iOS",
            "//Lib/dist/dynamic:tvOS",
            "//Lib/dist/dynamic:watchOS",
            "//tvOSApp",
        ],
        target_environments = ["device", "simulator"],
    ),
    "//Bundle",
    top_level_targets(
        labels = [
            "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
            "//iOSApp/Test/UITests:iOSAppUITests",
        ],
        target_environments = ["device", "simulator"],
    ),
    "//iOSApp/Test/TestingUtils:macos_TestingUtils",
    "//iMessageApp",
    top_level_target(
        label = "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
        target_environments = ["device", "simulator"],
    ),
    "//macOSApp/Source:macOSApp",
    "//macOSApp/Test/UITests:macOSAppUITests",
    "//tvOSApp/Test/UITests:tvOSAppUITests",
    "//tvOSApp/Test/UnitTests:tvOSAppUnitTests",
    "//watchOSApp/Test/UITests:watchOSAppUITests",
    "//watchOSAppExtension/Test/UnitTests:watchOSAppExtensionUnitTests",
    "//iOSApp/Test:iOSAppTestSuite",
    "//iOSApp/Test/UITests:iOSAppUITestSuite",
    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTestSuite",
    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTestSuite",
    "//Proto:proto",
    "//GRPC:echo_client",
    "//GRPC:echo_server",
]

IOS_BUNDLE_ID = "rules-xcodeproj.example"
TEAMID = "V82V4GQZXM"

APP_CLIP_BUNDLE_ID = "{}.app-clip".format(IOS_BUNDLE_ID)
TVOS_BUNDLE_ID = IOS_BUNDLE_ID
WATCHOS_BUNDLE_ID = "{}.watch".format(IOS_BUNDLE_ID)

SCHEME_AUTOGENERATION_MODE = "all"
SCHEME_AUTOGENERATION_CONFIG = xcschemes.autogeneration_config(
    scheme_name_exclude_patterns = [
        ".*UndesiredScheme.*",
        ".*UnwantedScheme.*",
    ],
    test = xcschemes.autogeneration.test(
        options = xcschemes.test_options(
            app_language = "en",
            app_region = "US",
            code_coverage = False,
        ),
    ),
)

def get_xcode_schemes():
    return [
        xcode_schemes.scheme(
            name = "iOSAppUnitTests_Scheme",
            test_action = xcode_schemes.test_action(
                env = {
                    "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
                },
                targets = [
                    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
                    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
                ],
                post_actions = [
                    xcode_schemes.pre_post_action(
                        name = "Run After Tests",
                        script = "echo \"Hi\"",
                        expand_variables_based_on = "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
                    ),
                ],
            ),
        ),
        xcode_schemes.scheme(
            name = "iOSAppSwiftUnitTests_Scheme",
            test_action = xcode_schemes.test_action(
                build_configuration = "AppStore",
                env = {
                    "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
                },
                targets = [
                    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
                ],
            ),
        ),
        xcode_schemes.scheme(
            name = "iOSAppUnitTestSuite_CommandLineArgs_Scheme",
            test_action = xcode_schemes.test_action(
                args = [
                    "--command_line_args=-AppleLanguages,(en)",
                ],
                env = {
                    "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
                },
                targets = [
                    "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTestSuite",
                    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTestSuite",
                ],
                post_actions = [
                    xcode_schemes.pre_post_action(
                        name = "Run After Tests",
                        script = "echo \"Hi\"",
                        expand_variables_based_on = "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTestSuite",
                    ),
                ],
            ),
        ),
    ]

XCSCHEMES = [
    xcschemes.scheme(
        name = "iOSAppUnitTests_Scheme",
        test = xcschemes.test(
            env = {
                "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
            },
            test_targets = [
                xcschemes.test_target(
                    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
                    post_actions = [
                        xcschemes.pre_post_actions.launch_script(
                            title = "Run After Tests",
                            script_text = "echo \"Hi\"",
                        ),
                    ],
                ),
                "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTests",
            ],
        ),
    ),
    xcschemes.scheme(
        name = "iOSAppSwiftUnitTests_Scheme",
        test = xcschemes.test(
            xcode_configuration = "AppStore",
            env = {
                "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
            },
            test_options = xcschemes.test_options(
                app_language = "en",
                app_region = "US",
                code_coverage = False,
            ),
            test_targets = [
                "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTests",
            ],
        ),
    ),
    xcschemes.scheme(
        name = "iOSAppUnitTestSuite_CommandLineArgs_Scheme",
        test = xcschemes.test(
            args = [
                "-AppleLanguages",
                "(en)",
            ],
            env = {
                "IOSAPPSWIFTUNITTESTS_CUSTOMSCHEMEVAR": "TRUE",
            },
            test_targets = [
                "//iOSApp/Test/ObjCUnitTests:iOSAppObjCUnitTestSuite",
                xcschemes.test_target(
                    "//iOSApp/Test/SwiftUnitTests:iOSAppSwiftUnitTestSuite",
                    post_actions = [
                        xcschemes.pre_post_actions.launch_script(
                            title = "Run After Tests",
                            script_text = "echo \"Hi\"",
                        ),
                    ],
                ),
            ],
        ),
    ),
    xcschemes.scheme(
        name = "ios_build_test",
        run = xcschemes.run(
            build_targets = [
                xcschemes.top_level_anchor_target(
                    "//Lib:ios_Lib",
                    library_targets = [
                        "//Lib",
                    ],
                ),
            ],
        ),
    ),
]
