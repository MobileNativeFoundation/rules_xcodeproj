""" Allows for the creation of modulemaps given a list of headers """

load("@build_bazel_rules_swift//swift:swift.bzl", "SwiftInfo")

HEADERS_FILE_TYPES = [
    ".h",
    ".hh",
    ".hpp",
    ".ipp",
    ".hxx",
    ".h++",
    ".inc",
    ".inl",
    ".tlh",
    ".tli",
    ".H",
    ".hmap",
]

def _module_map_content(
        module_name,
        hdrs,
        textual_hdrs,
        swift_generated_header,
        module_map_path):
    # Up to the execution root
    # bazel-out/<platform-config>/bin/<path/to/package>/<target-name>.modulemaps/<module-name>
    slashes_count = module_map_path.count("/")
    relative_path = "".join(["../"] * slashes_count)

    content = "module " + module_name + " {\n"

    for hdr in hdrs:
        if hdr.extension == "h":
            content += "  header \"%s%s\"\n" % (relative_path, hdr.path)
    for hdr in textual_hdrs:
        if hdr.extension == "h":
            content += "  textual header \"%s%s\"\n" % (relative_path, hdr.path)

    content += "\n"
    content += "  export *\n"
    content += "}\n"

    # Add a Swift submodule if a Swift generated header exists
    if swift_generated_header:
        content += "\n"
        content += "module " + module_name + ".Swift {\n"
        content += "  header \"%s\"\n" % swift_generated_header.basename
        content += "  requires objc\n"
        content += "}\n"

    return content

def _umbrella_header_content(hdrs):
    # If the platform is iOS, add an import call to `UIKit/UIKit.h` to the top
    # of the umbrella header. This allows implicit import of UIKit from Swift.
    content = """\
#ifdef __OBJC__
#import <Foundation/Foundation.h>
#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif
#endif

"""
    for hdr in hdrs:
        if hdr.extension == "h":
            content += "#import \"%s\"\n" % (hdr.path)

    return content

def _impl(ctx):
    outputs = []

    hdrs = ctx.files.hdrs
    textual_hdrs = ctx.files.textual_hdrs
    outputs.extend(hdrs)
    outputs.extend(textual_hdrs)

    # Find Swift generated header
    swift_generated_header = None
    for dep in ctx.attr.deps:
        if CcInfo in dep:
            objc_headers = dep[CcInfo].compilation_context.headers.to_list()
        else:
            objc_headers = []
        for hdr in objc_headers:
            if hdr.owner == dep.label:
                swift_generated_header = hdr
                outputs.append(swift_generated_header)

    # Write the module map content
    if swift_generated_header:
        umbrella_header_path = ctx.attr.module_name + ".h"
        umbrella_header = ctx.actions.declare_file(umbrella_header_path)
        outputs.append(umbrella_header)
        ctx.actions.write(
            content = _umbrella_header_content(hdrs),
            output = umbrella_header,
        )
        outputs.append(umbrella_header)

    module_map = ctx.outputs.out
    outputs.append(module_map)

    ctx.actions.write(
        content = _module_map_content(
            module_name = ctx.attr.module_name,
            hdrs = hdrs,
            textual_hdrs = textual_hdrs,
            swift_generated_header = swift_generated_header,
            module_map_path = module_map.path,
        ),
        output = module_map,
    )

    objc_provider = apple_common.new_objc_provider()

    compilation_context = cc_common.create_compilation_context(
        headers = depset(outputs),
    )
    cc_info = CcInfo(
        compilation_context = compilation_context,
    )

    return [
        DefaultInfo(
            files = depset([module_map]),
        ),
        objc_provider,
        cc_info,
    ]

_module_map = rule(
    implementation = _impl,
    attrs = {
        "module_name": attr.string(
            mandatory = True,
            doc = "The name of the module.",
        ),
        "hdrs": attr.label_list(
            allow_files = HEADERS_FILE_TYPES,
            doc = """\
The list of C, C++, Objective-C, and Objective-C++ header files used to
construct the module map.
""",
        ),
        "textual_hdrs": attr.label_list(
            allow_files = HEADERS_FILE_TYPES,
            doc = """\
The list of C, C++, Objective-C, and Objective-C++ header files used to
construct the module map. Unlike hdrs, these will be declared as 'textual
header' in the module map.
""",
        ),
        "deps": attr.label_list(
            providers = [SwiftInfo],
            doc = """\
The list of swift_library targets.  A `${module_name}.Swift` submodule will be
generated if non-empty.
""",
        ),
        "add_to_provider": attr.bool(
            default = True,
            doc = """\
Whether to add the generated module map to the returning provider. Targets
imported via `apple_static_framework_import` or
`apple_dynamic_framework_import` already have their module maps provided to
swift_library targets depending on them. Set this to `False` in that case to
avoid duplicate modules.
""",
        ),
        "out": attr.output(
            doc = "The name of the output module map file.",
        ),
    },
    doc = "Generates a module map given a list of header files.",
    provides = [
        DefaultInfo,
    ],
)

def module_map(name, **kwargs):
    _module_map(
        name = name,
        out = name + "-module.modulemap",
        **kwargs
    )
