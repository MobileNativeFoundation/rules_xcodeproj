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

def write_generate_bazel_dependencies_script(
        *,
        actions,
        generator_label,
        template):
    """Writes the `generate_bazel_dependencies.sh` script.

    Args:
        actions: `ctx.actions`.
        generator_label: The `Label` of the `xcodeproj` generator target.
        template: `xcodeproj/internal/templates/generate_bazel_dependencies.sh`.

    Returns:
        The `File` for `generate_bazel_dependencies.sh`.
    """
    output = actions.declare_file(
        "{}_bazel_integration_files/generate_bazel_dependencies.sh".format(
            generator_label.name,
        ),
    )

    actions.expand_template(
        template = template,
        output = output,
        is_executable = True,
        substitutions = {
            "%swiftcopt%": str(Label("@build_bazel_rules_swift//swift:copt")),
        },
    )

    return output
