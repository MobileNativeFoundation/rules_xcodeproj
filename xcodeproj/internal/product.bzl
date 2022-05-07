"""Functions for calculating a target's product."""

load(
    ":files.bzl",
    "file_path",
    "file_path_to_dto",
)
load(":linker_input_files.bzl", "linker_input_files")

def process_product(
        *,
        target,
        product_name,
        product_type,
        bundle_file_path,
        linker_inputs,
        build_settings):
    """Generates information about the target's product.

    Args:
        target: The `Target` the product information is gathered from.
        product_name: The name of the product (i.e. the "PRODUCT_NAME" build
            setting).
        product_type: A PBXProductType string. See
            https://github.com/tuist/XcodeProj/blob/main/Sources/XcodeProj/Objects/Targets/PBXProductType.swift
            for examples.
        bundle_file_path: If the product is a bundle, this is `file_path` to the
            bundle, otherwise `None`.
        linker_inputs: A value returned by `linker_input_files.collect`.
        build_settings: A mutable `dict` that will be updated with Xcode build
            settings.

    Returns:
        A `struct` containing the name, the path to the product and the product type.
    """
    if bundle_file_path:
        fp = bundle_file_path
    elif target[DefaultInfo].files_to_run.executable:
        fp = file_path(target[DefaultInfo].files_to_run.executable)
    elif CcInfo in target:
        fp = linker_input_files.get_primary_static_library(linker_inputs)
    else:
        fp = None

    if not fp:
        fail("Could not find product for target {}".format(target.label))

    build_settings["PRODUCT_NAME"] = product_name

    return struct(
        name = product_name,
        path = fp,
        type = product_type,
    )

# TODO: Make this into a module
def product_to_dto(product):
    return {
        "name": product.name,
        "path": file_path_to_dto(product.path) if product.path else None,
        "type": product.type,
    }
