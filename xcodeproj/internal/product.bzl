"""Functions for calculating a target's product."""

load(
    ":files.bzl",
    "file_path",
)
load(":linker_input_files.bzl", "linker_input_files")

def _codesign_executable(*, ctx, executable):
    executable_path = "rules_xcodeproj/{}/{}".format(
        ctx.rule.attr.name,
        executable.basename,
    )
    entitlements = ctx.actions.declare_file(
        "{}.entitlements".format(executable_path),
    )
    output = ctx.actions.declare_file(executable_path)

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

    ctx.actions.run_shell(
        inputs = [executable, entitlements],
        outputs = [output],
        command = """\
cp -c "{input}" "{output}"
chmod u+w "{output}"

/usr/bin/codesign --force --sign - --entitlements "{entitlements}" --timestamp=none --generate-entitlement-der "{output}" 2>&1 | grep -v "replacing existing signature"
exit ${{PIPESTATUS[0]}}
""".format(
            entitlements = entitlements.path,
            input = executable.path,
            output = output.path,
        ),
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
        fp = bundle_file_path
        actual_fp = archive_file_path
    elif target[DefaultInfo].files_to_run.executable:
        file = _codesign_executable(
            ctx = ctx,
            executable = target[DefaultInfo].files_to_run.executable,
        )
        fp = file_path(file)
        actual_fp = fp
    elif CcInfo in target and linker_inputs:
        file = linker_input_files.get_primary_static_library(linker_inputs)
        fp = file_path(file) if file else None
        actual_fp = fp
    else:
        file = None
        fp = None
        actual_fp = None

    if not fp:
        fail("Could not find product for target {}".format(target.label))

    if target and apple_common.AppleDynamicFramework in target:
        linker_files = (
            target[apple_common.AppleDynamicFramework].framework_files
        )
    else:
        linker_files = depset()

    return struct(
        executable_name = executable_name,
        name = product_name,
        linker_files = linker_files,
        file = file,
        file_path = fp,
        actual_file_path = actual_fp,
        type = product_type,
        is_resource_bundle = is_resource_bundle,
    )
