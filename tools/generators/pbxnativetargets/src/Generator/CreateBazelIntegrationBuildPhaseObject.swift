import PBXProj

extension Generator {
    struct CreateBazelIntegrationBuildPhaseObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates the Bazel integration build phase object for a target.
        func callAsFunction(
            subIdentifier: Identifiers.Targets.SubIdentifier,
            productType: PBXProductType
        ) -> Object {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*productType:*/ productType
            )
        }
    }
}

// MARK: - CreateBazelIntegrationBuildPhaseObject.Callable

extension Generator.CreateBazelIntegrationBuildPhaseObject {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ productType: PBXProductType
    ) -> Object

    static func defaultCallable(
        subIdentifier: Identifiers.Targets.SubIdentifier,
        productType: PBXProductType
    ) -> Object {
        let shellScript = #"""
set -euo pipefail

if [[ "$ACTION" == "indexbuild" ]]; then
  cd "$SRCROOT"

  "$BAZEL_INTEGRATION_DIR/generate_index_build_bazel_dependencies.sh"
else
  "$BAZEL_INTEGRATION_DIR/copy_outputs.sh" \
    "_BazelForcedCompile_.swift" \
    "\#(productType.rsyncExcludeFile)"
fi

"""#

        let infoPlistInputPath: String
        if productType.isBundle {
            infoPlistInputPath = #"""
				"$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)",

"""#
        } else {
            infoPlistInputPath = ""
        }

        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
\#(infoPlistInputPath)\#
			);
			name = \#(BuildPhase.bazelIntegration.name.pbxProjEscaped);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = \#(shellScript.pbxProjEscaped);
			showEnvVarsInLog = 0;
		}
"""#

        return Object(
            identifier: Identifiers.Targets.buildPhase(
                .bazelIntegration,
                subIdentifier: subIdentifier
            ),
            content: content
        )
    }
}

private extension PBXProductType {
    var rsyncExcludeFile: String {
        switch self {
        case .application,
            .messagesApplication,
            .onDemandInstallCapableApplication,
            .watch2AppContainer:
            return "$BAZEL_INTEGRATION_DIR/app.exclude.rsynclist"
        case .framework:
            return "$BAZEL_INTEGRATION_DIR/framework.exclude.rsynclist"
        case .unitTestBundle,
            .uiTestBundle:
            return "$BAZEL_INTEGRATION_DIR/xctest.exclude.rsynclist"
        case .appExtension,
            .extensionKitExtension,
            .intentsServiceExtension,
            .messagesExtension,
            .tvExtension,
            .watch2Extension:
            return "$BAZEL_INTEGRATION_DIR/appex.exclude.rsynclist"
        case .watch2App:
            return "$BAZEL_INTEGRATION_DIR/watchos2_app.exclude.rsynclist"
        default:
            return ""
        }
    }
}
