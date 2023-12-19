"""Module for collecting product information for a target, when using \
`generation_mode = "incremental"`."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//xcodeproj/internal/files:files.bzl", "join_paths_ignoring_empty")
load("//xcodeproj/internal/files:linker_input_files.bzl", "linker_input_files")

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

def _calculate_packge_bin_dir(*, bin_dir_path, label):
    return join_paths_ignoring_empty(
        bin_dir_path,
        label.workspace_root,
        label.package,
    )

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
    args.add(output.path)

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
    )

    return output

def _collect_product(
        *,
        actions,
        bundle_extension = None,
        bundle_file = None,
        bundle_name = None,
        bundle_path = None,
        executable_name = None,
        linker_inputs,
        target,
        product_name,
        product_type):
    """Generates information about the target's product.

    Args:
        actions: `ctx.actions`.
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
        linker_inputs: A value returned by `linker_input_files.collect`.
        product_name: The name of the product (i.e. the "PRODUCT_NAME" build
            setting).
        product_type: A value from `PRODUCT_TYPE_ENCODED`.
        target: The `Target` the product information is gathered from.

    Returns:
        A `struct` with the following fields:

        *   `file`: The `File` that Bazel needs to produce in order to allow
            `copy_outputs.sh` to work. Will be an unarchived bundle, a binary
            inside of a bundle, a code-signed binary, or a static library
            archive.
        *   `path`: The path to the product that we care about. This can be a
            parent directory of `file` in the case of some bundles. This is
            the codesigned binary for a binary target, or the unarchived bundle
            for a bundle target.
        *   `xcode_product`: A `struct` with the following fields:

            *   `basename`: The basename of `path`.
            *   `executable_name`: The `executable_name` argument.
            *   `name`: The `product_name` argument.
            *   `original_basename`: `basename` if the product isn't codesigned,
                otherwise it's the basename of the uncodesigned binary.
            *   `type`: The `product_type` argument.
    """
    if bundle_file and bundle_file.extension in _ARCHIVE_EXTENSIONS:
        file = _extract_archive(
            actions = actions,
            archive = bundle_file,
            bundle_name = bundle_name,
            bundle_extension = bundle_extension,
        )
        basename = file.basename
        original_basename = basename
        path = file.path
    elif bundle_path:
        # Tree artifacts, resource bundles, and `swift_test`
        file = bundle_file
        basename = paths.basename(bundle_path)
        original_basename = basename
        path = bundle_path
    elif target[DefaultInfo].files_to_run.executable:
        original_file = target[DefaultInfo].files_to_run.executable
        original_basename = original_file.basename
        file = _codesign_executable(
            actions = actions,
            executable = original_file,
        )
        basename = file.basename
        path = file.path
    elif CcInfo in target and linker_inputs and target.files != depset():
        file = linker_input_files.get_primary_static_library(linker_inputs)
        if file:
            basename = file.basename
            path = file.path
        else:
            basename = None
            path = None
        original_basename = basename
    else:
        file = None
        basename = None
        original_basename = None
        path = None

    return struct(
        file = file,
        path = path,
        xcode_product = struct(
            basename = basename,
            executable_name = executable_name,
            original_basename = original_basename,
            name = product_name,
            type = product_type,
        ),
    )

products = struct(
    calculate_packge_bin_dir = _calculate_packge_bin_dir,
    collect = _collect_product,
)
