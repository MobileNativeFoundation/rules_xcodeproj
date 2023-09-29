import PBXProj
import ToolCommon

extension Generator {
    struct CreateCreateCompileDependenciesBuildPhaseObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates the "Create Compile Dependencies" build phase object for a
        /// target.
        func callAsFunction(
            subIdentifier: Identifiers.Targets.SubIdentifier,
            hasCParams: Bool,
            hasCxxParams: Bool
        ) -> Object? {
            return callable(
                /*subIdentifier:*/ subIdentifier,
                /*hasCParams:*/ hasCParams,
                /*hasCxxParams:*/ hasCxxParams
            )
        }
    }
}

// MARK: - CreateCreateCompileDependenciesBuildPhaseObject.Callable

extension Generator.CreateCreateCompileDependenciesBuildPhaseObject {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ hasCParams: Bool,
        _ hasCxxParams: Bool
    ) -> Object?

    static func defaultCallable(
        subIdentifier: Identifiers.Targets.SubIdentifier,
        hasCParams: Bool,
        hasCxxParams: Bool
    ) -> Object? {
        var shellScriptComponents = ["set -euo pipefail\n"]

        var scriptIndex = 0
        func addProcessCompileParamsCommand() {
            shellScriptComponents.append(
                #"""
perl -pe '
  s/__BAZEL_XCODE_DEVELOPER_DIR__/\$(DEVELOPER_DIR)/g;
  s/__BAZEL_XCODE_SDKROOT__/\$(SDKROOT)/g;
  s/\$(\()?([a-zA-Z_]\w*)(?(1)\))/$ENV{$2}/gx;
' "$SCRIPT_INPUT_FILE_\#(scriptIndex)" > "$SCRIPT_OUTPUT_FILE_\#(scriptIndex)"

"""#
            )
            scriptIndex += 1
        }

        var inputPaths: [String] = []
        var outputPaths: [String] = []
        if hasCParams {
            inputPaths.append(#"""
				"$(C_PARAMS_FILE)",

"""#)
            outputPaths.append(#"""
				"$(DERIVED_FILE_DIR)/c.compile.params",

"""#)
            addProcessCompileParamsCommand()
        }
        if hasCxxParams {
            inputPaths.append(#"""
				"$(CXX_PARAMS_FILE)",

"""#)
            outputPaths.append(#"""
				"$(DERIVED_FILE_DIR)/cxx.compile.params",

"""#)
            addProcessCompileParamsCommand()
        }

        if shellScriptComponents.count == 1 {
            // We don't have anything to do (first element is a header)
            return nil
        }

        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
\#(inputPaths.joined())\#
			);
			name = "Create Compile Dependencies";
			outputPaths = (
\#(outputPaths.joined())\#
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = \#(
    shellScriptComponents.joined(separator: "\n").pbxProjEscaped
);
			showEnvVarsInLog = 0;
		}
"""#

        return Object(
            identifier: Identifiers.Targets.buildPhase(
                .createCompileDependencies,
                subIdentifier: subIdentifier
            ),
            content: content
        )
    }
}
