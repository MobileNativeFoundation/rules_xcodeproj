"""Tests for update_release_changelog."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.changelog import update_release_changelog


class update_release_changelog_test(unittest.TestCase):
    def test_rewrites_release_and_drops_tbd_only_sections(self):
        changelog = """# Changelog

<!--
BEGIN_UNRELEASED_TEMPLATE

<a id="unreleased"></a>
## [Unreleased]

[Unreleased]: https://github.com/MobileNativeFoundation/rules_xcodeproj/compare/%PREVIOUS_TAG%...HEAD

### New

* TBD

### Fixed

* TBD

END_UNRELEASED_TEMPLATE
-->

<a id="unreleased"></a>
## [Unreleased]

[Unreleased]: https://github.com/MobileNativeFoundation/rules_xcodeproj/compare/3.4.1...HEAD

### New

* Added thing
* TBD

### Fixed

* TBD

<a id="3.4.1"></a>
## [3.4.1] - 2025-11-19
"""

        actual = update_release_changelog.render_updated_changelog(
            changelog,
            tag="3.5.0",
            previous_tag="3.4.1",
            today="2026-05-03",
        )

        expected = """# Changelog

<!--
BEGIN_UNRELEASED_TEMPLATE

<a id="unreleased"></a>
## [Unreleased]

[Unreleased]: https://github.com/MobileNativeFoundation/rules_xcodeproj/compare/%PREVIOUS_TAG%...HEAD

### New

* TBD

### Fixed

* TBD

END_UNRELEASED_TEMPLATE
-->

<a id="unreleased"></a>
## [Unreleased]

[Unreleased]: https://github.com/MobileNativeFoundation/rules_xcodeproj/compare/3.5.0...HEAD

### New

* TBD

### Fixed

* TBD

<a id="3.5.0"></a>
## [3.5.0] - 2026-05-03

[3.5.0]: https://github.com/MobileNativeFoundation/rules_xcodeproj/compare/3.4.1...3.5.0

### New

* Added thing

<a id="3.4.1"></a>
## [3.4.1] - 2025-11-19
"""

        self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
