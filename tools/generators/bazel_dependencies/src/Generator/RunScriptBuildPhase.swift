import PBXProj

extension Generator {
    /// Calculates a Run Script `PBXShellScriptBuildPhase` element.
    ///
    /// - Parameters:
    ///   - name: The name of the script.
    ///   - script: The text of the script.
    static func runScriptBuildPhase(name: String, script: String?) -> String? {
        guard let script = script else {
            return nil
        }

        return #"""
{
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = \#("\(name) Run Script".pbxProjEscaped);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = \#(script.pbxProjEscaped);
			showEnvVarsInLog = 0;
		}
"""#
    }
}
