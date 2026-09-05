"""Deterministically assembles version 2 build-proxy manifest fragments."""

import json
from pathlib import Path
from typing import Iterable, Mapping, Sequence


SCHEMA_VERSION = 2
CAPABILITIES = {"actions": ["build", "clean", "indexbuild", "preview"]}
BAZELRC_PATH = "rules_xcodeproj/bazel/xcodeproj.bazelrc"
ADAPTER_PATH = "rules_xcodeproj/bazel/generate_bazel_dependencies.sh"
BAZEL_DEPENDENCIES_TARGET_GUID = "FF0100000000000000000001"
RECEIPT_SCHEMA_VERSION = 1
INVOCATION_ENVIRONMENT_KEYS = [
    "ACTION",
    "BAZEL_CONFIG",
    "BAZEL_EXTERNAL",
    "BAZEL_INTEGRATION_DIR",
    "BAZEL_OUT",
    "BAZEL_OUTPUT_BASE",
    "BAZEL_SEPARATE_INDEXBUILD_OUTPUT_BASE",
    "BAZEL_SUPPRESS_COVERAGE_BUILD",
    "CLANG_COVERAGE_MAPPING",
    "COLOR_DIAGNOSTICS",
    "DEVELOPER_DIR",
    "ENABLE_ADDRESS_SANITIZER",
    "ENABLE_PREVIEWS",
    "ENABLE_THREAD_SANITIZER",
    "ENABLE_UNDEFINED_BEHAVIOR_SANITIZER",
    "HOME",
    "IMPORT_INDEX_BUILD_INDEXSTORES",
    "INDEX_DATA_STORE_DIR",
    "INDEXING_PROJECT_DIR__NO",
    "OBJROOT",
    "PROJECT_DIR",
    "RULES_XCODEPROJ_BUILD_MODE",
    "SRCROOT",
    "TERM",
    "TOOLCHAINS",
    "USER",
    "XCODE_PRODUCT_BUILD_VERSION",
    "XCODE_VERSION_ACTUAL",
]

_REQUIRED_ENTRY_KEYS = {
    "action",
    "bazelLabel",
    "configuration",
    "indexOutputGroups",
    "outputGroup",
    "previewOutputGroups",
    "product",
    "targetID",
    "variant",
    "xcodeTargetGUID",
}
_REQUIRED_PRODUCT_KEYS = {"basename", "materialization", "name", "type"}
_REQUIRED_VARIANT_KEYS = {"arch", "minimumOSVersion", "platform"}
_MATERIALIZATION_STRATEGIES = {"copy_file", "copy_tree", "none"}


class ManifestError(ValueError):
    """Raised when a generated manifest fragment violates the v2 contract."""


def _validate_entry(entry: object, source: str, line_number: int) -> Mapping:
    if not isinstance(entry, dict):
        raise ManifestError(f"{source}:{line_number}: entry must be an object")

    missing = _REQUIRED_ENTRY_KEYS - entry.keys()
    if missing:
        raise ManifestError(
            f"{source}:{line_number}: missing keys: {', '.join(sorted(missing))}"
        )
    if entry["action"] != "build":
        raise ManifestError(
            f"{source}:{line_number}: unsupported action: {entry['action']!r}"
        )

    target_id = entry["targetID"]
    output_group = entry["outputGroup"]
    if not isinstance(target_id, str) or not target_id:
        raise ManifestError(f"{source}:{line_number}: targetID must be a string")
    if output_group != f"bp {target_id}":
        raise ManifestError(
            f"{source}:{line_number}: outputGroup must identify targetID"
        )
    for name, prefixes in [
        ("indexOutputGroups", ("bc ", "bi ")),
        ("previewOutputGroups", ("bc ", "bp ", "bl ")),
    ]:
        values = entry[name]
        expected = [f"{prefix}{target_id}" for prefix in prefixes]
        if values != expected:
            raise ManifestError(
                f"{source}:{line_number}: {name} must identify targetID"
            )

    product = entry["product"]
    if not isinstance(product, dict):
        raise ManifestError(f"{source}:{line_number}: product must be an object")
    missing_product = _REQUIRED_PRODUCT_KEYS - product.keys()
    if missing_product:
        raise ManifestError(
            f"{source}:{line_number}: product missing keys: "
            f"{', '.join(sorted(missing_product))}"
        )
    strategy = product["materialization"]
    if strategy not in _MATERIALIZATION_STRATEGIES:
        raise ManifestError(
            f"{source}:{line_number}: unsupported materialization: {strategy!r}"
        )
    product_path = product.get("path")
    if strategy == "none" and product_path is not None:
        raise ManifestError(
            f"{source}:{line_number}: materialization 'none' must not declare a path"
        )
    if strategy != "none":
        if not isinstance(product_path, str) or not product_path.startswith("bazel-out/"):
            raise ManifestError(
                f"{source}:{line_number}: materializable product path must be under bazel-out/"
            )
        if ".." in Path(product_path).parts:
            raise ManifestError(
                f"{source}:{line_number}: product path must not contain traversal"
            )

    variant = entry["variant"]
    if not isinstance(variant, dict):
        raise ManifestError(f"{source}:{line_number}: variant must be an object")
    missing_variant = _REQUIRED_VARIANT_KEYS - variant.keys()
    if missing_variant:
        raise ManifestError(
            f"{source}:{line_number}: variant missing keys: "
            f"{', '.join(sorted(missing_variant))}"
        )

    return entry


def _entry_sort_key(entry: Mapping) -> tuple:
    variant = entry["variant"]
    return (
        entry["xcodeTargetGUID"],
        entry["configuration"],
        entry["action"],
        variant["platform"],
        variant["arch"],
        variant["minimumOSVersion"],
        entry["targetID"],
    )


def assemble(
    fragment_lines: Iterable[tuple[str, int, str]],
    *,
    bazel_path: str,
    generator_label: str,
    project_container: str,
) -> bytes:
    """Returns canonical v2 JSON bytes for named JSON Lines input."""
    if not generator_label:
        raise ManifestError("generator label must not be empty")
    if not bazel_path:
        raise ManifestError("Bazel path must not be empty")
    if not project_container or Path(project_container).name != project_container:
        raise ManifestError("project container must be a basename")
    if not project_container.endswith(".xcodeproj"):
        raise ManifestError("project container must end in .xcodeproj")

    entries = []
    for source, line_number, line in fragment_lines:
        if not line.strip():
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError as error:
            raise ManifestError(f"{source}:{line_number}: invalid JSON: {error}") from error
        entries.append(_validate_entry(entry, source, line_number))

    entries.sort(key=_entry_sort_key)
    for previous, current in zip(entries, entries[1:]):
        if _entry_sort_key(previous) == _entry_sort_key(current):
            raise ManifestError(
                "duplicate target mapping for "
                f"{current['xcodeTargetGUID']}/"
                f"{current['configuration']}/"
                f"{current['action']}/"
                f"{current['variant']['platform']}/"
                f"{current['variant']['arch']}/"
                f"{current['variant']['minimumOSVersion']}"
            )

    manifest = {
        "capabilities": CAPABILITIES,
        "ignoredXcodeTargetGUIDs": [BAZEL_DEPENDENCIES_TARGET_GUID],
        "invocation": {
            "adapterPath": ADAPTER_PATH,
            "bazelPath": bazel_path,
            "bazelrcPath": BAZELRC_PATH,
            "environmentKeys": INVOCATION_ENVIRONMENT_KEYS,
            "generatorLabel": generator_label,
            "receiptSchemaVersion": RECEIPT_SCHEMA_VERSION,
        },
        "project": {
            "containerName": project_container,
            "identity": generator_label,
        },
        "schemaVersion": SCHEMA_VERSION,
        "targets": entries,
    }
    return (
        json.dumps(
            manifest,
            ensure_ascii=False,
            separators=(",", ":"),
            sort_keys=True,
        )
        + "\n"
    ).encode("utf-8")


def assemble_files(
    paths: Sequence[Path],
    *,
    bazel_path: str,
    generator_label: str,
    project_container: str,
) -> bytes:
    lines = []
    for path in paths:
        with path.open(encoding="utf-8") as file:
            lines.extend(
                (str(path), line_number, line)
                for line_number, line in enumerate(file, start=1)
            )
    return assemble(
        lines,
        bazel_path=bazel_path,
        generator_label=generator_label,
        project_container=project_container,
    )


def write(
    output: Path,
    fragments: Sequence[Path],
    *,
    bazel_path: str,
    generator_label: str,
    project_container: str,
) -> None:
    output.write_bytes(
        assemble_files(
            fragments,
            bazel_path=bazel_path,
            generator_label=generator_label,
            project_container=project_container,
        )
    )
