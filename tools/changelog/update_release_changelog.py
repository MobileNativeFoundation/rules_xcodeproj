#!/usr/bin/env python3

"""Updates CHANGELOG.md for a release and resets the Unreleased section."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

BEGIN_TEMPLATE_MARKER = "BEGIN_UNRELEASED_TEMPLATE"
END_TEMPLATE_MARKER = "END_UNRELEASED_TEMPLATE"
UNRELEASED_SECTION_RE = re.compile(
    r'<a id="unreleased"></a>\n## \[Unreleased\]\n',
)
NEXT_SECTION_RE = re.compile(r'\n<a id="[^"]+"></a>\n## \[')
SECTION_RE = re.compile(r"(?m)^### .+$")
TBD_LINE_RE = re.compile(r"\s*[*-]\s*TBD\s*")


def _extract_template(text: str) -> str:
    begin_idx = text.find(BEGIN_TEMPLATE_MARKER)
    end_idx = text.find(END_TEMPLATE_MARKER)
    if begin_idx == -1 or end_idx == -1:
        raise ValueError("Unreleased template markers not found in CHANGELOG.md")

    template_block = text[begin_idx:end_idx].splitlines()
    template_lines: list[str] = []
    in_block = False
    for line in template_block:
        if line.strip() == BEGIN_TEMPLATE_MARKER:
            in_block = True
            continue
        if in_block:
            template_lines.append(line)

    template = "\n".join(template_lines).strip("\n")
    if not template:
        raise ValueError("Unreleased template content is empty")

    return template


def _find_unreleased_section(text: str, search_start: int) -> tuple[int, int]:
    unreleased_match = UNRELEASED_SECTION_RE.search(text[search_start:])
    if not unreleased_match:
        raise ValueError("Unreleased section not found in CHANGELOG.md")
    unreleased_start = search_start + unreleased_match.start()

    next_anchor = NEXT_SECTION_RE.search(text[unreleased_start + 1 :])
    if not next_anchor:
        raise ValueError("Unable to find end of Unreleased section")
    unreleased_end = unreleased_start + 1 + next_anchor.start()

    return unreleased_start, unreleased_end


def _remove_tbd_only_sections(release_section: str) -> str:
    section_matches = list(SECTION_RE.finditer(release_section))
    if not section_matches:
        return release_section

    preamble = release_section[: section_matches[0].start()].rstrip("\n")
    kept_sections: list[str] = []
    for idx, match in enumerate(section_matches):
        start = match.start()
        end = (
            section_matches[idx + 1].start()
            if idx + 1 < len(section_matches)
            else len(release_section)
        )
        section = release_section[start:end].strip("\n")
        lines = section.splitlines()
        heading = lines[0]
        body_lines = [line for line in lines[1:] if not TBD_LINE_RE.fullmatch(line)]
        while body_lines and not body_lines[0].strip():
            body_lines.pop(0)
        while body_lines and not body_lines[-1].strip():
            body_lines.pop()
        if body_lines:
            kept_sections.append("\n".join([heading, "", *body_lines]))

    if not kept_sections:
        return preamble

    return f"{preamble}\n\n" + "\n\n".join(kept_sections)


def render_updated_changelog(
    text: str,
    *,
    tag: str,
    previous_tag: str,
    today: str,
) -> str:
    template = _extract_template(text)
    search_start = text.find(END_TEMPLATE_MARKER)
    unreleased_start, unreleased_end = _find_unreleased_section(text, search_start)

    unreleased_section = text[unreleased_start:unreleased_end].strip("\n")
    release_section = unreleased_section
    release_section = release_section.replace(
        '<a id="unreleased"></a>', f'<a id="{tag}"></a>', 1
    )
    release_section = release_section.replace(
        "## [Unreleased]", f"## [{tag}] - {today}", 1
    )
    release_section = re.sub(
        r"\[Unreleased\]: .*",
        f"[{tag}]: https://github.com/MobileNativeFoundation/rules_xcodeproj/compare/{previous_tag}...{tag}",
        release_section,
        count=1,
    )
    release_section = _remove_tbd_only_sections(release_section)

    new_unreleased = template.replace("%PREVIOUS_TAG%", tag)
    return (
        text[:unreleased_start].rstrip("\n")
        + "\n\n"
        + new_unreleased.strip("\n")
        + "\n\n"
        + release_section.strip("\n")
        + "\n\n"
        + text[unreleased_end:].lstrip("\n")
    )


def update_changelog(path: Path, *, tag: str, previous_tag: str, today: str) -> None:
    text = path.read_text()
    updated_text = render_updated_changelog(
        text,
        tag=tag,
        previous_tag=previous_tag,
        today=today,
    )
    path.write_text(updated_text)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--changelog", default="CHANGELOG.md")
    parser.add_argument("--tag", required=True)
    parser.add_argument("--previous-tag", required=True)
    parser.add_argument("--today", required=True)
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    update_changelog(
        Path(args.changelog),
        tag=args.tag,
        previous_tag=args.previous_tag,
        today=args.today,
    )


if __name__ == "__main__":
    main()
