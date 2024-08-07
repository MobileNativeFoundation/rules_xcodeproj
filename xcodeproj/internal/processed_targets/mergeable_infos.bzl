"""Module for calculating mergeable info for processed targets."""

load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "EMPTY_LIST",
    "EMPTY_STRING",
    "memory_efficient_depset",
)
load("//xcodeproj/internal:xcodeprojinfo.bzl", "XcodeProjInfo")

_FRAMEWORK_PRODUCT_TYPE = "f"  # com.apple.product-type.framework

_PREVIEWS_ENABLED_PRODUCT_TYPES = {
    "A": None,  # com.apple.product-type.application.on-demand-install-capable
    "E": None,  # com.apple.product-type.extensionkit-extension
    "W": None,  # com.apple.product-type.watchkit2-extension
    "a": None,  # com.apple.product-type.application
    "e": None,  # com.apple.product-type.app-extension
    "f": None,  # com.apple.product-type.framework
    "m": None,  # com.apple.product-type.app-extension.messages
    "t": None,  # com.apple.product-type.tv-app-extension
    "u": None,  # com.apple.product-type.bundle.unit-test
    "w": None,  # com.apple.product-type.application.watchapp2
}

def _cc_mergeable_info(*, id, mergeable_info):
    return struct(
        compile_target_ids = mergeable_info.id,
        compile_target_ids_list = [mergeable_info.id],
        conly_args = mergeable_info.args.conly,
        cxx_args = mergeable_info.args.cxx,
        extra_file_paths = mergeable_info.inputs.extra_file_paths,
        extra_files = mergeable_info.inputs.extra_files,
        indexstores = mergeable_info.indexstores,
        ids = [(id, (mergeable_info.id,))],
        module_name = mergeable_info.module_name,
        non_arc_srcs = mergeable_info.inputs.non_arc_srcs,
        package_bin_dir = mergeable_info.package_bin_dir,
        previews_dynamic_frameworks = EMPTY_LIST,
        previews_include_path = EMPTY_STRING,
        product_files = (mergeable_info.product_file,),
        srcs = mergeable_info.inputs.srcs,
        swift_args = EMPTY_LIST,
        swift_debug_settings_to_merge = mergeable_info.swift_debug_settings,
    )

def _calculate_mergeable_info(
        *,
        avoid_deps,
        deps_infos,
        dynamic_frameworks,
        id,
        product_type,
        xcode_inputs):
    # We can only merge if this target doesn't have its own sources
    if xcode_inputs.srcs or xcode_inputs.non_arc_srcs:
        return None

    avoid_ids = {
        id: None
        for id in depset(
            transitive = [
                dep[XcodeProjInfo].transitive_dependencies
                for dep in avoid_deps
            ],
        ).to_list()
    }

    mergeable_infos = depset(
        transitive = [
            info.mergeable_infos
            for info in deps_infos
        ],
    ).to_list()
    mergeable_infos = [
        info
        for info in mergeable_infos
        if info.id not in avoid_ids
    ]

    if len(mergeable_infos) == 1:
        # We can always add merge targets of a single library dependency
        mergeable_info = mergeable_infos[0]

        if not mergeable_info.id:
            # `None` for `id` means the library target was explicitly unfocused
            return None

        if mergeable_info.swiftmodule:
            return _swift_mergeable_info(
                dynamic_frameworks = dynamic_frameworks,
                id = id,
                mergeable_info = mergeable_info,
                product_type = product_type,
            )
        else:
            return _cc_mergeable_info(
                id = id,
                mergeable_info = mergeable_info,
            )

    if len(mergeable_infos) == 2:
        # Only merge if one src is Swift and the other isn't
        mergeable_info1 = mergeable_infos[0]
        mergeable_info2 = mergeable_infos[1]

        if not mergeable_info1.id and not mergeable_info2.id:
            # `None` for `id` means the library target was explicitly unfocused
            return None

        mergeable_info1_is_swift = mergeable_info1.swiftmodule
        mergeable_info2_is_swift = mergeable_info2.swiftmodule

        # Only merge 1 Swift and 1 non-Swift target for now
        if ((mergeable_info1_is_swift and mergeable_info2_is_swift) or
            (not mergeable_info1_is_swift and not mergeable_info2_is_swift)):
            return None

        cc = mergeable_info1 if mergeable_info2_is_swift else mergeable_info2
        swift = mergeable_info1 if mergeable_info1_is_swift else mergeable_info2

        if not cc.id:
            return _swift_mergeable_info(
                dynamic_frameworks = dynamic_frameworks,
                id = id,
                mergeable_info = swift,
                product_type = product_type,
            )
        if not swift.id:
            return _cc_mergeable_info(
                id = id,
                mergeable_info = cc,
            )

        previews_info = _previews_info(
            swift,
            dynamic_frameworks = dynamic_frameworks,
            product_type = product_type,
        )

        return struct(
            compile_target_ids = swift.id + " " + cc.id,
            compile_target_ids_list = [swift.id, cc.id],
            conly_args = cc.args.conly,
            cxx_args = cc.args.cxx,
            extra_file_paths = memory_efficient_depset(
                transitive = [
                    swift.inputs.extra_file_paths,
                    cc.inputs.extra_file_paths,
                ],
            ),
            extra_files = memory_efficient_depset(
                transitive = [
                    swift.inputs.extra_files,
                    cc.inputs.extra_files,
                ],
            ),
            indexstores = list(swift.indexstores) + list(cc.indexstores),
            ids = [(id, (swift.id, cc.id))],
            module_name = swift.module_name,
            non_arc_srcs = cc.inputs.non_arc_srcs,
            package_bin_dir = swift.package_bin_dir,
            previews_dynamic_frameworks = previews_info.frameworks,
            previews_include_path = previews_info.include_path,
            product_files = (
                swift.product_file,
                cc.product_file,
            ),
            srcs = memory_efficient_depset(
                transitive = [
                    swift.inputs.srcs,
                    cc.inputs.srcs,
                ],
            ),
            swift_args = swift.args.swift,
            swift_debug_settings_to_merge = memory_efficient_depset(
                transitive = [
                    mergeable_infos[0].swift_debug_settings,
                    mergeable_infos[1].swift_debug_settings,
                ],
                order = "topological",
            ),
        )

    # Unmergeable source target count
    return None

def _previews_info(
        mergeable_info,
        *,
        dynamic_frameworks,
        product_type):
    if not product_type in _PREVIEWS_ENABLED_PRODUCT_TYPES:
        return struct(
            frameworks = EMPTY_LIST,
            include_path = EMPTY_STRING,
        )

    if mergeable_info.swiftmodule:
        include_path = mergeable_info.swiftmodule.dirname
    else:
        include_path = EMPTY_STRING

    if product_type != _FRAMEWORK_PRODUCT_TYPE:
        dynamic_frameworks = EMPTY_LIST

    return struct(
        frameworks = dynamic_frameworks,
        include_path = include_path,
    )

def _swift_mergeable_info(
        *,
        dynamic_frameworks,
        id,
        mergeable_info,
        product_type):
    previews_info = _previews_info(
        mergeable_info,
        dynamic_frameworks = dynamic_frameworks,
        product_type = product_type,
    )

    return struct(
        compile_target_ids = mergeable_info.id,
        compile_target_ids_list = [mergeable_info.id],
        conly_args = EMPTY_LIST,
        cxx_args = EMPTY_LIST,
        extra_file_paths = mergeable_info.inputs.extra_file_paths,
        extra_files = mergeable_info.inputs.extra_files,
        indexstores = mergeable_info.indexstores,
        ids = [(id, (mergeable_info.id,))],
        module_name = mergeable_info.module_name,
        non_arc_srcs = EMPTY_DEPSET,
        package_bin_dir = mergeable_info.package_bin_dir,
        previews_dynamic_frameworks = previews_info.frameworks,
        previews_include_path = previews_info.include_path,
        product_files = (mergeable_info.product_file,),
        srcs = mergeable_info.inputs.srcs,
        swift_args = mergeable_info.args.swift,
        swift_debug_settings_to_merge = mergeable_info.swift_debug_settings,
    )

mergeable_infos = struct(
    calculate = _calculate_mergeable_info,
)
