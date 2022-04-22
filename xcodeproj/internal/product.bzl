"""Functions for calculating a target's product."""

load(":collections.bzl", "flatten")
load(
    ":files.bzl",
    "file_path",
    "file_path_to_dto",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")

def get_linker_inputs(*, cc_info):
    return cc_info.linking_context.linker_inputs

def get_static_framework_files(*, objc):
    if not objc:
        return depset()
    return objc.static_framework_file

def get_static_libraries(*, linker_inputs, static_framework_files):
    static_libraries = [
        library.static_library
        for library in flatten([
            input.libraries
            for input in linker_inputs.to_list()
        ])
    ]
    return static_libraries + static_framework_files.to_list()

def _get_static_library(*, linker_inputs):
    for input in linker_inputs.to_list():
        # Ideally we would only return the static library that is owned by this
        # target, but sometimes another rule creates the output and this rule
        # outputs it. So far the first library has always been the correct one.
        return file_path(input.libraries[0].static_library)
    return None

def process_product(
        *,
        target,
        product_name,
        product_type,
        bundle_path,
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
        bundle_path: If the product is a bundle, this is the the path to the
            bundle, otherwise `None`.
        linker_inputs: A `depset` of `LinkerInput`s for this target.
        build_settings: A mutable `dict` that will be updated with Xcode build
            settings.

    Returns:
        A struct containing the name, the path to the product and the product type.
    """
    if bundle_path:
        fp = bundle_path
    elif target[DefaultInfo].files_to_run.executable:
        fp = file_path(target[DefaultInfo].files_to_run.executable)
    elif CcInfo in target or SwiftInfo in target:
        fp = _get_static_library(linker_inputs = linker_inputs)
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
