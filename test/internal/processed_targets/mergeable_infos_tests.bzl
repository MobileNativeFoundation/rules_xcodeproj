"""Tests for dependency framework metadata on merged Preview targets."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal/processed_targets:mergeable_infos.bzl", "mergeable_infos")

def _mergeable_preview_frameworks_test_impl(ctx):
    env = unittest.begin(ctx)
    source = ctx.actions.declare_file("Subject.swift")
    module = ctx.actions.declare_file("Subject.swiftmodule")
    archive = ctx.actions.declare_file("libSubject.a")
    dependency = ctx.actions.declare_file("Dependency.framework/Dependency")
    for file in [source, module, archive, dependency]:
        ctx.actions.write(file, "fixture\n")

    swift_preview_inputs = struct(manifests = (), files = depset(), paths = ())
    info = struct(
        args = struct(
            conly = (),
            cxx = (),
            swift = ("-Onone", "-DTEST"),
            swift_preview_inputs = swift_preview_inputs,
        ),
        id = "subject-id",
        indexstores = (),
        inputs = struct(
            extra_file_paths = depset(["extra/path"]),
            extra_files = depset(),
            non_arc_srcs = depset(),
            srcs = depset([source]),
        ),
        module_name = "Subject",
        package_bin_dir = "bazel-out/config/bin/package",
        premerged_info = None,
        product_file = archive,
        swift_debug_settings = depset(),
        swiftmodule = module,
    )

    previews_enabled_types = ["A", "E", "W", "a", "e", "f", "m", "t", "u", "w"]
    results = {}
    for product_type in previews_enabled_types + ["l", "unknown"]:
        results[product_type] = mergeable_infos.calculate(
            avoid_deps = [],
            deps_infos = [struct(mergeable_infos = depset([info]))],
            dynamic_frameworks = (dependency,),
            product_type = product_type,
            xcode_inputs = struct(srcs = depset(), non_arc_srcs = depset()),
        )

    framework = results["f"]
    asserts.equals(env, (dependency,), framework.merged.previews_dynamic_frameworks)
    asserts.equals(env, ("subject-id",), framework.ids)
    asserts.equals(env, [source], framework.merged.srcs.to_list())
    asserts.equals(env, info.args.swift, framework.merged.swift_args)
    asserts.equals(env, (archive,), framework.merged.product_files)
    asserts.equals(env, module.dirname, framework.merged.previews_include_path)

    for product_type, result in results.items():
        expected_frameworks = (dependency,) if product_type in ["a", "f"] else []
        asserts.equals(
            env,
            expected_frameworks,
            result.merged.previews_dynamic_frameworks,
            "dependency frameworks for product type {}".format(product_type),
        )
        asserts.equals(env, framework.ids, result.ids)

        # Preserve every existing merged field (including IDs, source sets,
        # compiler arguments and Preview import metadata), not only frameworks.
        for field in dir(framework.merged):
            if field in ["previews_dynamic_frameworks", "previews_include_path", "to_json", "to_proto"]:
                continue
            asserts.equals(
                env,
                getattr(framework.merged, field),
                getattr(result.merged, field),
                "{} unchanged for product type {}".format(field, product_type),
            )
        asserts.equals(
            env,
            module.dirname if product_type in previews_enabled_types else "",
            result.merged.previews_include_path,
        )

    cc_fields = {key: getattr(info, key) for key in dir(info) if key not in ["to_json", "to_proto"]}
    cc_fields.update(
        id = "clang-id",
        swiftmodule = None,
        args = struct(
            conly = ("-DC",),
            cxx = (),
            swift = (),
            swift_preview_inputs = struct(manifests = (), files = depset([source]), paths = ()),
        ),
    )
    cc_info = struct(**cc_fields)
    for infos in [[cc_info], [info, cc_info]]:
        merged = mergeable_infos.calculate(
            avoid_deps = [],
            deps_infos = [struct(mergeable_infos = depset(infos))],
            dynamic_frameworks = (),
            product_type = "a",
            xcode_inputs = struct(srcs = depset(), non_arc_srcs = depset()),
        ).merged
        asserts.equals(env, [source], merged.swift_preview_inputs.files.to_list())

    return unittest.end(env)

mergeable_preview_frameworks_test = unittest.make(_mergeable_preview_frameworks_test_impl)

def mergeable_infos_test_suite(name):
    unittest.suite(name, mergeable_preview_frameworks_test)
