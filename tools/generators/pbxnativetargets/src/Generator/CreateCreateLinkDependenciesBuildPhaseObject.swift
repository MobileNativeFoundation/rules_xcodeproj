import PBXProj
import ToolCommon

extension Generator {
    struct CreateCreateLinkDependenciesBuildPhaseObject {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(callable: @escaping Callable = Self.defaultCallable) {
            self.callable = callable
        }

        /// Creates the "Create Link Dependencies" build phase object for a
        /// target.
        func callAsFunction(
            subIdentifier: Identifiers.Targets.SubIdentifier,
            hasCompileStub: Bool,
            isStaticLibrary: Bool = false
        ) -> Object {
            return callable(
                /* subIdentifier: */ subIdentifier,
                /* hasCompileStub: */ hasCompileStub,
                /* isStaticLibrary: */ isStaticLibrary
            )
        }
    }
}

// MARK: - CreateCreateLinkDependenciesBuildPhaseObject.Callable

extension Generator.CreateCreateLinkDependenciesBuildPhaseObject {
    typealias Callable = (
        _ subIdentifier: Identifiers.Targets.SubIdentifier,
        _ hasCompileStub: Bool,
        _ isStaticLibrary: Bool
    ) -> Object

    static func defaultCallable(
        subIdentifier: Identifiers.Targets.SubIdentifier,
        hasCompileStub: Bool,
        isStaticLibrary: Bool = false
    ) -> Object {
        let runtimeAction = isStaticLibrary ? #"""
if [[ "${BAZEL_NATIVE_PREVIEWS:-}" == "YES" && "${ACTION:-}" == build ]]; then
  # Script phases have CURRENT_ARCH=undefined_arch. Use the selected target,
  # never the host architecture or an unrelated ambient toolchain directory.
  # Explicit exit is necessary: macOS sh can report success for a failed
  # parameter expansion when an EXIT trap is installed.
  for runtime_setting in ARCHS LLVM_TARGET_TRIPLE_VENDOR LLVM_TARGET_TRIPLE_OS_VERSION; do
    if [[ -z "${!runtime_setting:-}" ]]; then
      echo "error: Missing Preview build setting $runtime_setting" >&2
      exit 1
    fi
  done
  read -r -a runtime_archs <<< "$ARCHS"
  if [[ "${#runtime_archs[@]}" != 1 ]]; then
    echo "error: Preview runtime planning requires exactly one ARCHS value: $ARCHS" >&2
    exit 1
  fi
  runtime_target="${runtime_archs[0]}-${LLVM_TARGET_TRIPLE_VENDOR}-${LLVM_TARGET_TRIPLE_OS_VERSION}"
  runtime_target+="${LLVM_TARGET_TRIPLE_SUFFIX:-}"
  /usr/bin/python3 "$BAZEL_INTEGRATION_DIR/preview_runtime_link_params.py" \
    --driver "${LD:-}" \
    --sdk "${SDK_DIR:-}" \
    --target "$runtime_target" \
    --swift-profile "${BAZEL_PREVIEW_SWIFT_PROFILE:-NO}" \
    --driver-policy-file "$SCRIPT_INPUT_FILE_1" >> "$link_params_tmp"
fi

"""# : ""
        let action = #"""
readonly link_params_tmp="$(mktemp "$SCRIPT_OUTPUT_FILE_0.tmp.XXXXXX")"
trap 'rm -f "$link_params_tmp"' EXIT
perl -pe 's/\$(\()?([a-zA-Z_]\w*)(?(1)\))/$ENV{$2}/g' \
  < "$SCRIPT_INPUT_FILE_0" > "$link_params_tmp"
\#(runtimeAction)\#
chmod 0644 "$link_params_tmp"
mv -f "$link_params_tmp" "$SCRIPT_OUTPUT_FILE_0"
trap - EXIT
"""#
        let indexGuard = isStaticLibrary
            ? #"[[ "${ACTION:-}" != indexbuild && "${INDEX_ENABLE_BUILD_ARENA:-}" != YES ]] && "#
            : ""
        var shellScriptComponents: [String] = [
            #"""
set -euo pipefail

if \#(indexGuard)\#
[[ "${ENABLE_PREVIEWS:-}" == "YES" || \
      "${BAZEL_NATIVE_PREVIEWS:-}" == "YES" ]]; then
\#(action)
else
  # A prior Preview build may have populated this response file. Truncate it
  # so ordinary linker and Libtool tasks cannot consume stale Preview inputs.
  : > "$SCRIPT_OUTPUT_FILE_0"
fi

"""#,
        ]

        var outputPaths = [#"""
				"$(DERIVED_FILE_DIR)/link.params",
"""#]
        let runtimeInputs = isStaticLibrary ? #"""
				"$(LINK_PARAMS_FILE)$(BAZEL_PREVIEW_RUNTIME_POLICY_SUFFIX)",
				"$(BAZEL_INTEGRATION_DIR)/preview_runtime_link_params.py",
				"$(LD)",
				"$(SDK_DIR)/SDKSettings.plist",

"""# : ""
        if hasCompileStub {
            outputPaths.append(#"""
				"$(DERIVED_FILE_DIR)/_CompileStub_.m",
"""#)
            shellScriptComponents.append(#"""
touch "$SCRIPT_OUTPUT_FILE_1"

"""#)
        }

        // The tabs for indenting are intentional
        let content = #"""
{
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"$(LINK_PARAMS_FILE)",
\#(runtimeInputs)\#
			);
			name = "Create Link Dependencies";
			outputPaths = (
\#(outputPaths.joined(separator: "\n"))
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
                .createLinkDependencies,
                subIdentifier: subIdentifier
            ),
            content: content
        )
    }
}
