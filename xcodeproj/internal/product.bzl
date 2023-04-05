"""Functions for calculating a target's product."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    ":files.bzl",
    "file_path",
)
load(":linker_input_files.bzl", "linker_input_files")

def _codesign_executable(*, ctx, executable):
    executable_path = "{}_codesigned".format(
        executable.basename,
    )
    entitlements = ctx.actions.declare_file(
        "{}.entitlements".format(executable_path),
        sibling = executable,
    )
    output = ctx.actions.declare_file(
        executable_path,
        sibling = executable,
    )

    ctx.actions.run_shell(
        outputs = [entitlements],
        command = """\
cat > "{entitlements}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>com.apple.security.get-task-allow</key>
        <true/>
</dict>
</plist>
EOF
""".format(entitlements = entitlements.path),
    )

    args = ctx.actions.args()
    args.add(executable)
    args.add(output)
    args.add(entitlements)

    ctx.actions.run_shell(
        inputs = [executable, entitlements],
        outputs = [output],
        command = """\
if [[ $(stat -f '%d' "$1") == $(stat -f '%d' "${2%/*}") ]]; then
  cp -c "$1" "$2"
else
  cp "$1" "$2"
fi
chmod u+w "$2"

/usr/bin/codesign --force --sign - --entitlements "$3" --timestamp=none --generate-entitlement-der "$2" 2>&1 | grep -v "replacing existing signature"
exit ${PIPESTATUS[0]}
""",
        arguments = [args],
        # Share mnemonic with rules_apple's codesigning, so if
        # `--modify_execution_info` is used to adjust code signing, it applies
        # to this as well
        mnemonic = "SignBinary",
        execution_requirements = {
            # Disable sandboxing for codesigning
            "no-sandbox": "1",
        },
    )

    return output

def process_product(
        *,
        ctx,
        target,
        product_name,
        product_type,
        is_resource_bundle = False,
        bundle_file = None,
        bundle_path = None,
        bundle_file_path = None,
        archive_file_path = None,
        executable_name = None,
        linker_inputs):
    """Generates information about the target's product.

    Args:
        ctx: The aspect context.
        target: The `Target` the product information is gathered from.
        product_name: The name of the product (i.e. the "PRODUCT_NAME" build
            setting).
        product_type: A PBXProductType string. See
            https://github.com/tuist/XcodeProj/blob/main/Sources/XcodeProj/Objects/Targets/PBXProductType.swift
            for examples.
        is_resource_bundle: Whether the product is a resource bundle.
        bundle_file: If the product is a bundle, this is `File` for the bundle,
            otherwise `None`.
        bundle_path: If the product is a bundle, this is the path to
            the bundle, when not in an archive, otherwise `None`.
        bundle_file_path: If the product is a bundle, this is the `file_path` to
            the bundle, when not in an archive, otherwise `None`.
        archive_file_path: If the product is a bundle, this is
            `file_path` to the bundle, possibly in an archive, otherwise `None`.
        executable_name: If the product is a bundle, this is the executable
            name, otherwise `None`.
        linker_inputs: A value returned by `linker_input_files.collect`.

    Returns:
        A `struct` containing the name, the path to the product and the product type.
    """
    if bundle_file_path:
        file = bundle_file
        basename = paths.basename(bundle_file_path.path)
        fp = bundle_file_path
        actual_fp = archive_file_path
    elif target[DefaultInfo].files_to_run.executable:
        executable = target[DefaultInfo].files_to_run.executable
        file = _codesign_executable(ctx = ctx, executable = executable)
        basename = file.basename
        fp = file_path(executable)
        actual_fp = fp
    elif CcInfo in target and linker_inputs and target.files != depset():
        file = linker_input_files.get_primary_static_library(linker_inputs)
        basename = file.basename if file else None
        fp = file_path(file) if file else None
        actual_fp = fp
    else:
        file = None
        basename = None
        fp = None
        actual_fp = None

    if bundle_path:
        path = bundle_path
    elif file:
        path = file.path
    else:
        path = None

    if target and apple_common.AppleDynamicFramework in target:
        framework_files = (
            target[apple_common.AppleDynamicFramework].framework_files
        )
    else:
        framework_files = depset()

    if target and apple_common.AppleExecutableBinary in target:
        executable = target[apple_common.AppleExecutableBinary].binary
    else:
        executable = None

    if target:
        label = target.label
        package_dir = paths.join(
            label.workspace_name,
            ctx.bin_dir.path,
            label.package,
        )
    else:
        package_dir = None

    return struct(
        executable = executable,
        executable_name = executable_name,
        name = product_name,
        framework_files = framework_files,
        file = file,
        path = path,
        basename = basename,
        file_path = fp,
        actual_file_path = actual_fp,
        package_dir = package_dir,
        type = product_type,
        is_resource_bundle = is_resource_bundle,
    )
