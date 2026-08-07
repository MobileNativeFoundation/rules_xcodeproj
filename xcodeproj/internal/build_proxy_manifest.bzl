"""Actions for creating the versioned build-proxy manifest."""

def write_build_proxy_manifest(
        *,
        actions,
        bazel_path,
        entries_files,
        generator_label,
        name,
        project_container,
        tool):
    """Assembles deterministic shard entries into the v2 proxy manifest.

    Args:
        actions: `ctx.actions`.
        bazel_path: The Bazel executable path recorded for proxy invocation.
        entries_files: JSON Lines manifest fragments from target shards.
        generator_label: The `xcodeproj` generator label the proxy must build.
        name: The generator target name.
        project_container: Basename of the generated `.xcodeproj` bundle.
        tool: The executable that validates and assembles the manifest.

    Returns:
        The generated build proxy manifest `File`.
    """
    output = actions.declare_file(
        "{}_bazel_integration_files/build_proxy_manifest.json".format(name),
    )

    args = actions.args()
    args.add(output)
    args.add(str(generator_label))
    args.add(bazel_path)
    args.add(project_container)
    args.add_all(entries_files)

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = entries_files,
        outputs = [output],
        mnemonic = "WriteBuildProxyManifest",
        progress_message = "Generating %{output}",
    )

    return output
