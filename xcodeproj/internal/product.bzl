"""Functions for calculating a target's product, when using \
`generation_mode = "legacy"`."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//xcodeproj/internal/files:linker_input_files.bzl", "linker_input_files")
load(":memory_efficiency.bzl", "EMPTY_DEPSET")

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

_ARCHIVE_EXTENSIONS = {
    "ipa": None,
    "zip": None,
}

def _codesign_executable(*, actions, executable):
    executable_path = "{}_codesigned".format(
        executable.basename,
    )
    entitlements = actions.declare_file(
        "{}.entitlements".format(executable_path),
        sibling = executable,
    )
    output = actions.declare_file(
        executable_path,
        sibling = executable,
    )

    actions.run_shell(
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

    args = actions.args()
    args.add(executable)
    args.add(output)
    args.add(entitlements)

    actions.run_shell(
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

def _extract_archive(*, actions, archive, bundle_name, bundle_extension):
    output = actions.declare_directory(
        bundle_name + bundle_extension,
        sibling = archive,
    )

    args = actions.args()
    args.add(archive)
    args.add_all([output], expand_directories = False)

    actions.run_shell(
        inputs = [archive],
        outputs = [output],
        command = """\
set -eu

readonly archive="$1"
readonly output="$2"

if [[ "$archive" = *.ipa ]]; then
    suffix=/Payload
else
    suffix=
fi

expanded_dir=$(mktemp -d)
trap 'rm -rf "$expanded_dir"' EXIT

unzip -q -DD "$archive" -d "$expanded_dir"
mv "$expanded_dir$suffix/${output##*/}" "${output%/*}"
""",
        arguments = [args],
        mnemonic = "XcodeProjExtractBundleArchive",
        execution_requirements = {
            # Similar to our recommendations on `BundleApp`, by default it
            # doesn't make sense to cache the output of this action
            "no-cache": "1",
            # Similar to our recommendations on `BundleApp`, by default it
            # doesn't make sense to cache transfer the input or output of this
            # action over the network
            "no-remote": "1",
        },
    )

    return output

def process_product(
        *,
        actions,
        bin_dir_path,
        bundle_extension = None,
        bundle_file = None,
        bundle_name = None,
        bundle_path = None,
        executable_name = None,
        is_resource_bundle = False,
        linker_inputs,
        module_name_attribute,
        product_name,
        product_type,
        target):
    """Generates information about the target's product.

    Args:
        actions: `ctx.actions`.
        bin_dir_path: `ctx.bin_dir.path`.
        bundle_extension: If the product is a bundle, the extension of the
            unarchived bundle, otherwise `None`.
        bundle_file: If the product is a bundle, this is `File` for the bundle,
            otherwise `None`.
        bundle_name: If the product is a bundle, this is the name of the
            unarchived bundle, without the extension, otherwise `None`.
        bundle_path: If the product is a bundle, this is the path to
            the bundle, when not in an archive, otherwise `None`.
        executable_name: If the product is a bundle, this is the executable
            name, otherwise `None`.
        module_name_attribute: The `module_name` attribute of `target`.
        product_name: The name of the product (i.e. the "PRODUCT_NAME" build
            setting).
        product_type: A PBXProductType string. See
            https://github.com/tuist/XcodeProj/blob/main/Sources/XcodeProj/Objects/Targets/PBXProductType.swift
            for examples.
        is_resource_bundle: Whether the product is a resource bundle.
        linker_inputs: A value returned by `linker_input_files.collect`.
        target: The `Target` the product information is gathered from.

    Returns:
        A `struct` with various fields describing the product.
    """
    if bundle_file and bundle_file.extension in _ARCHIVE_EXTENSIONS:
        file = _extract_archive(
            actions = actions,
            archive = bundle_file,
            bundle_name = bundle_name,
            bundle_extension = bundle_extension,
        )
        basename = file.basename
        path = file.path
        fp = path
        original_path = path
    elif bundle_path:
        # Tree artifacts, resource bundles, and `swift_test`
        file = bundle_file
        basename = paths.basename(bundle_path)
        path = bundle_path
        fp = path
        original_path = path
    elif target[DefaultInfo].files_to_run.executable:
        executable = target[DefaultInfo].files_to_run.executable
        file = _codesign_executable(actions = actions, executable = executable)
        basename = file.basename
        fp = executable.path
        original_path = fp
        path = file.path
    elif CcInfo in target and linker_inputs and target.files != depset():
        file = linker_input_files.get_primary_static_library(linker_inputs)
        if file:
            basename = file.basename
            fp = file.path
        else:
            basename = None
            fp = None
        original_path = fp
        path = fp
    else:
        file = None
        basename = None
        fp = None
        original_path = None
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
        label = target.label
        package_dir = paths.join(
            label.workspace_name,
            bin_dir_path,
            label.package,
        )
    else:
        package_dir = None

    return struct(
        basename = basename,
        executable = executable,
        executable_name = executable_name,
        file = file,
        file_path = fp,
        framework_files = framework_files,
        is_resource_bundle = is_resource_bundle,
        module_name_attribute = module_name_attribute,
        name = product_name,
        original_path = original_path,
        package_dir = package_dir,
        path = path,
        type = product_type,
    )
