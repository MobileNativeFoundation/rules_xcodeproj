import XCScheme

extension ExecutionAction {
    private static let initializeBazelBuildOutputGroupsFileScriptText = #"""
mkdir -p "${BUILD_MARKER_FILE%/*}"
touch "$BUILD_MARKER_FILE"

"""#.schemeXmlEscaped

    static func initializeBazelBuildOutputGroupsFile(
        with buildableReference: BuildableReference
    ) -> Self {
        return Self(
            title: "Initialize Bazel Build Output Groups File",
            escapedScriptText: initializeBazelBuildOutputGroupsFileScriptText,
            expandVariablesBasedOn: buildableReference
        )
    }

    private static let prepareBazelDependenciesScriptText = #"""
mkdir -p "$PROJECT_DIR"

if [[ "${ENABLE_ADDRESS_SANITIZER:-}" == "YES" || \
      "${ENABLE_THREAD_SANITIZER:-}" == "YES" || \
      "${ENABLE_UNDEFINED_BEHAVIOR_SANITIZER:-}" == "YES" ]]
then
    # TODO: Support custom toolchains once clang.sh supports them
    cd "$INTERNAL_DIR" || exit 1
    ln -shfF "$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib" lib
fi

"""#.schemeXmlEscaped

    /// Symlinks `$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/lib` to
    /// `$(BAZEL_INTEGRATION_DIR)/../lib` so that Xcode can copy sanitizers'
    /// dylibs.
    static func prepareBazelDependencies(
        with buildableReference: BuildableReference
    ) -> Self {
        return Self(
            title: "Prepare BazelDependencies",
            escapedScriptText: prepareBazelDependenciesScriptText,
            expandVariablesBasedOn: buildableReference
        )
    }

    private static let updateLldbInitAndCopyDSYMsScriptText = #"""
"$BAZEL_INTEGRATION_DIR/create_lldbinit.sh"
"$BAZEL_INTEGRATION_DIR/copy_dsyms.sh"

"""#.schemeXmlEscaped

    static func updateLldbInitAndCopyDSYMs(
        for buildableReference: BuildableReference
    ) -> Self {
        return Self(
            title: "Update .lldbinit and copy dSYMs",
            escapedScriptText: updateLldbInitAndCopyDSYMsScriptText,
            expandVariablesBasedOn: buildableReference
        )
    }
}
