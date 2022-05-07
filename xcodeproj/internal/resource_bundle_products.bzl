"""Functions to deal with resource bundle products."""

load(":files.bzl", "file_path_to_dto")

def _collect(
        *,
        bundle_file_path = None,
        owner,
        is_consuming_bundle,
        bundle_resources,
        attrs_info,
        transitive_infos):
    if not bundle_resources:
        return struct(
            _unowned_products = depset(),
            _owners = depset(),
            _owned_products = depset(),
            _products = depset(),
        )

    if owner:
        transitive_unowned_products = depset(
            transitive = [
                info.resource_bundles._unowned_products
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in attrs_info.xcode_targets.get(attr, [None]))
            ],
        )
        owned_products = [
            (owner, bundle_file_path)
            for bundle_file_path in transitive_unowned_products.to_list()
        ]
        unowned_products = depset(
            [bundle_file_path] if bundle_file_path else None,
        )
    else:
        owned_products = []
        unowned_products = depset(
            [bundle_file_path] if bundle_file_path else None,
            transitive = [
                info.resource_bundles._unowned_products
                for attr, info in transitive_infos
                if (not attrs_info or
                    info.target_type in attrs_info.xcode_targets.get(attr, [None]))
            ],
        )

    products = depset(
        owned_products,
        transitive = [
            info.resource_bundles._owned_products
            for _, info in transitive_infos
        ],
    )

    if is_consuming_bundle:
        propagate = depset()
        consume = products
    else:
        propagate = products
        consume = depset()

    return struct(
        _unowned_products = unowned_products,
        _owners = depset(
            [owner] if owner else None,
            transitive = [
                info.resource_bundles._owners
                for _, info in transitive_infos
            ],
        ),
        _owned_products = propagate,
        _products = consume,
    )

def _to_dto(resource_bundles, *, avoid_infos):
    """Generates a target DTO value for resource bundle products.

    Args:
        resource_bundles: A value returned from
            `resource_bundle_products.collect`.
        avoid_infos: A list of `XcodeProjInfo`s for the targets that already
            consumed resource bundle products, and their resource bundle
            products shouldn't be included in the DTO.

    Returns:
        A `list` of resource bundle product paths.
    """
    avoid_bundle_product_owners = depset(
        transitive = [
            info.resource_bundles._owners
            for _, info in avoid_infos
        ],
    ).to_list()

    return [
        file_path_to_dto(bundle_path)
        for owner, bundle_path in resource_bundles._products.to_list()
        if owner not in avoid_bundle_product_owners
    ]

resource_bundle_products = struct(
    collect = _collect,
    to_dto = _to_dto,
)
