"""Module for collecting dependencies. Only to be used when \
`xcodeproj.generation_mode = "incremental"` is set."""

load(":memory_efficiency.bzl", "memory_efficient_depset")

_WATCHKIT2 = "w"  # "com.apple.product-type.application.watchapp2"
_WATCHKIT2_EXTENSION = "W"  # "com.apple.product-type.watchkit2-extension"

def _collect_dependencies(
        *,
        top_level_product_type = None,
        test_host = None,
        transitive_infos):
    """Logic for processing target dependencies.

    Args:
        top_level_product_type: If this target is a top-level target, then a
            value from `PRODUCT_TYPE_ENCODED` in `product.bzl`, else `None`.
        test_host: The `xcode_target.id` of the target that is the test host for
            this target, or `None` if this target does not have a test host.
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of `target`.

    Returns:
        A `tuple` containing two elements:

        *   A `depset` of direct dependencies.
        *   A `depset` of direct and transitive dependencies.
    """
    direct_dependencies = []
    direct_transitive_dependencies = []
    transitive_direct_dependencies = []
    all_transitive_dependencies = []
    for info in transitive_infos:
        all_transitive_dependencies.append(info.transitive_dependencies)
        xcode_target = info.xcode_target
        if xcode_target:
            if (
                # Test hosts need to be copied
                test_host == xcode_target.id or
                # watchOS 2 App Extensions need to be embedded
                (top_level_product_type == _WATCHKIT2 and
                 xcode_target.product.type == _WATCHKIT2_EXTENSION)
            ):
                direct_dependencies.append(xcode_target.id)
            transitive_direct_dependencies.append(xcode_target.id)
        else:
            # We pass on the next level of dependencies if the previous target
            # didn't create an Xcode target.
            direct_transitive_dependencies.append(info.direct_dependencies)

    direct = memory_efficient_depset(
        direct_dependencies,
        transitive = direct_transitive_dependencies,
    )
    transitive = memory_efficient_depset(
        transitive_direct_dependencies,
        transitive = all_transitive_dependencies,
    )
    return (direct, transitive)

dependencies = struct(
    collect = _collect_dependencies,
)
