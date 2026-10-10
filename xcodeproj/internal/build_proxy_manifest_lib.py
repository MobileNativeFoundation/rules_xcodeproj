"""Deterministically assembles version 1 build-proxy manifest fragments."""

import json
from pathlib import Path
from typing import Iterable, Mapping, Sequence


SCHEMA_VERSION = 1
CAPABILITIES = {"actions": ["build"]}
BAZELRC_PATH = "rules_xcodeproj/bazel/xcodeproj.bazelrc"
BAZEL_DEPENDENCIES_TARGET_GUID = "FF0100000000000000000001"

_REQUIRED_ENTRY_KEYS = {
    "action",
    "bazelLabel",
    "configuration",
    "outputGroup",
    "product",
    "targetID",
    "variant",
    "xcodeTargetGUID",
}
_REQUIRED_PRODUCT_KEYS = {"basename", "name", "type"}
_REQUIRED_VARIANT_KEYS = {"arch", "minimumOSVersion", "platform"}


class ManifestError(ValueError):
    """Raised when a generated manifest fragment violates the v1 contract."""


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

    product = entry["product"]
    if not isinstance(product, dict):
        raise ManifestError(f"{source}:{line_number}: product must be an object")
    missing_product = _REQUIRED_PRODUCT_KEYS - product.keys()
    if missing_product:
        raise ManifestError(
            f"{source}:{line_number}: product missing keys: "
            f"{', '.join(sorted(missing_product))}"
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
) -> bytes:
    """Returns canonical v1 JSON bytes for named JSON Lines input."""
    if not generator_label:
        raise ManifestError("generator label must not be empty")
    if not bazel_path:
        raise ManifestError("Bazel path must not be empty")

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
            "bazelPath": bazel_path,
            "bazelrcPath": BAZELRC_PATH,
            "generatorLabel": generator_label,
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
    )


def write(
    output: Path,
    fragments: Sequence[Path],
    *,
    bazel_path: str,
    generator_label: str,
) -> None:
    output.write_bytes(
        assemble_files(
            fragments,
            bazel_path=bazel_path,
            generator_label=generator_label,
        )
    )
