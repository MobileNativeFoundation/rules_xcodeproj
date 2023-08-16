"""Actions for writing Bazel integration files."""

def write_bazel_build_script(
        *,
        actions,
        bazel_env,
        bazel_path,
        generator_label,
        target_ids_list,
        template):
    """Writes the `bazel_build.sh` script.

    Args:
        actions: `ctx.actions`.
        bazel_env: `xcodeproj.bazel_env`.
        bazel_path: `xcodeproj.bazel_path`.
        generator_label: The `Label` of the `xcodeproj` generator target.
        target_ids_list: The `target_ids` `File`.
        template: `xcodeproj/internal/templates/bazel_build.sh`.

    Returns:
        The `File` for `bazel_build.sh`.
    """
    output = actions.declare_file(
        "{}_bazel_integration_files/bazel_build.sh".format(
            generator_label.name,
        ),
    )

    envs = []
    for key, value in bazel_env.items():
        envs.append("  '{}={}'".format(
            key,
            (value
                .replace(
                # Escape single quotes for bash
                "'",
                "'\"'\"'",
            )),
        ))

    actions.expand_template(
        template = template,
        output = output,
        is_executable = True,
        substitutions = {
            "%bazel_env%": "\n".join(envs),
            "%bazel_path%": bazel_path,
            "%generator_label%": str(generator_label),
            "%target_ids_list%": (
                "$PROJECT_DIR/{}".format(target_ids_list.path)
            ),
        },
    )

    return output

def write_create_xcode_overlay_script(
        *,
        actions,
        generator_name,
        targets,
        template):
    """Writes the `create_xcode_overlay.sh` script.

    Args:
        actions: `ctx.actions`.
        generator_name: The name of the `xcodeproj` generator target.
        targets: A `dict` mapping target ids to `xcode_target`s.
        template: `xcodeproj/internal/templates/create_xcode_overlay.sh`.

    Returns:
        The `File` for `create_xcode_overlay.sh`.
    """
    output = actions.declare_file(
        "{}_bazel_integration_files/create_xcode_overlay.sh".format(
            generator_name,
        ),
    )

    roots = []
    for xcode_target in targets.values():
        generated_header = xcode_target.outputs.swift_generated_header
        if not generated_header:
            continue

        path = generated_header.path
        build_dir = "$BUILD_DIR/{}".format(path)
        bazel_out = "$BAZEL_OUT{}".format(path[9:])

        roots.append("""\
{{"external-contents": "{build_dir}","name": "${{bazel_out_prefix}}{bazel_out}","type": "file"}}\
""".format(bazel_out = bazel_out, build_dir = build_dir))

    actions.expand_template(
        template = template,
        output = output,
        is_executable = True,
        substitutions = {
            "%roots%": ",".join(sorted(roots)),
        },
    )

    return output
