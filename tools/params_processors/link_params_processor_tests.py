"""Tests for link_params_processor."""

import unittest

from tools.params_processors import link_params_processor


class LinkParamsProcessorTest(unittest.TestCase):

    def test_bundle_does_not_consume_following_linker_option(self):
        self.assertEqual(
            link_params_processor._process_linkopts(
                ["-bundle", "-ObjC", "-framework", "Foundation"],
                is_framework = False,
                generated_product_paths = [],
            ),
            ["-ObjC", "-framework", "Foundation"],
        )


if __name__ == "__main__":
    unittest.main()
