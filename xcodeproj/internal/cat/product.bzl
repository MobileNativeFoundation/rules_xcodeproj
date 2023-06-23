"""Functions for calculating a target's product."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//xcodeproj/internal:memory_efficiency.bzl", "EMPTY_DEPSET")
load(":linker_input_files.bzl", "linker_input_files")

# Values here need to match those in `PBXProductType.swift`
PRODUCT_TYPE_ENCODED = {
    "com.apple.product-type.app-extension": "e",
    "com.apple.product-type.app-extension.intents-service": "i",
    "com.apple.product-type.app-extension.messages": "m",
    "com.apple.product-type.app-extension.messages-sticker-pack": "s",
    "com.apple.product-type.application": "a",
    "com.apple.product-type.application.messages": "M",
    "com.apple.product-type.application.on-demand-install-capable": "A",
    "com.apple.product-type.application.watchapp2": "w",
    "com.apple.product-type.application.watchapp2-container": "c",
    # Resource bundles, which are also "com.apple.product-type.bundle" are "b"
    "com.apple.product-type.bundle": "B",
    "com.apple.product-type.bundle.ocunit-test": "o",
    "com.apple.product-type.bundle.ui-testing": "U",
    "com.apple.product-type.bundle.unit-test": "u",
    "com.apple.product-type.driver-extension": "d",
    "com.apple.product-type.extensionkit-extension": "E",
    "com.apple.product-type.framework": "f",
    "com.apple.product-type.framework.static": "F",
    "com.apple.product-type.instruments-package": "I",
    "com.apple.product-type.library.dynamic": "l",
    "com.apple.product-type.library.static": "L",
    "com.apple.product-type.metal-library": "3",
    "com.apple.product-type.system-extension": "S",
    "com.apple.product-type.tool": "T",
    "com.apple.product-type.tv-app-extension": "t",
    "com.apple.product-type.watchkit2-extension": "W",
    "com.apple.product-type.xcframework": "x",
    "com.apple.product-type.xcode-extension": "2",
    "com.apple.product-type.xpc-service": "X",
}

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

def from_resource_bundle(bundle):
    basename = bundle.name + ".bundle"
    path = "{}/{}".format(bundle.package_bin_dir, basename)

    return struct(
        executable = None,
        executable_name = None,
        name = bundle.name,
        module_name = None,
        module_name_attribute = bundle.name,
        framework_files = EMPTY_DEPSET,
        file = None,
        path = path,
        basename = basename,
        file_path = path,
        actual_file_path = None,
        package_dir = bundle.package_bin_dir,
        type = "b",  # com.apple.product-type.bundle (resource bundle)
    )

def process_product(
        *,
        ctx,
        label,
        target,
        product_name,
        product_type,
        module_name,
        module_name_attribute,
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
        module_name:  The module name of the product (i.e. the
            "PRODUCT_MODULE_NAME" build setting).
        module_name_attribute: The `module_name` attribute of `target`.
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
        basename = paths.basename(bundle_file_path)
        fp = bundle_file_path
        actual_fp = archive_file_path
    elif target[DefaultInfo].files_to_run.executable:
        executable = target[DefaultInfo].files_to_run.executable
        file = _codesign_executable(ctx = ctx, executable = executable)
        basename = file.basename
        fp = executable.path
        actual_fp = fp
    elif CcInfo in target and linker_inputs and target.files != depset():
        file = linker_input_files.get_primary_static_library(linker_inputs)
        basename = file.basename if file else None
        fp = file.path if file else None
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
        framework_files = EMPTY_DEPSET

    if target and apple_common.AppleExecutableBinary in target:
        executable = target[apple_common.AppleExecutableBinary].binary
    else:
        executable = None

    if target:
        package_dir = paths.join(
            label.workspace_name,
            ctx.bin_dir.path,
            label.package,
        )
    else:
        package_dir = None

    # FIXME: Make this smaller
    return struct(
        executable = executable,
        executable_name = executable_name,
        name = product_name,
        module_name = module_name,
        module_name_attribute = module_name_attribute,
        framework_files = framework_files,
        file = file,
        path = path,
        basename = basename,
        file_path = fp,
        actual_file_path = actual_fp,
        package_dir = package_dir,
        type = product_type,
    )
