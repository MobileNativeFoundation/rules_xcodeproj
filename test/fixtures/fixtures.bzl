"""Functions for updating test fixtures."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//xcodeproj:xcodeproj.bzl", "internal", "XcodeProjOutputInfo")

def _install_path(xcodeproj):
    # "example/ios_app/p.xcodeproj" -> "test/fixtures/ios_app/p.xcodeproj"
    return paths.join(
        "test/fixtures",
        xcodeproj.short_path.split("/")[1],
        "project.xcodeproj",
    )

def _update_fixtures_impl(ctx):
    specs = [target[XcodeProjOutputInfo].spec for target in ctx.attr.targets]
    xcodeprojs = [
        target[XcodeProjOutputInfo].xcodeproj for target in ctx.attr.targets
    ]

    installers = [
        internal.write_installer(
            ctx = ctx,
            name = "xcodeproj-{}".format(idx),
            install_path = _install_path(xcodeproj),
            xcodeproj = xcodeproj,
        )
        for idx, xcodeproj in enumerate(xcodeprojs)
    ]

    updater = ctx.actions.declare_file(
        "{}-updater.sh".format(ctx.label.name),
    )

    ctx.actions.expand_template(
        template = ctx.file._updater_template,
        output = updater,
        is_executable = True,
        substitutions = {
            "%specs%": "  \n".join([spec.short_path for spec in specs]),
            "%installers%": "  \n".join(
                [installer.short_path for installer in installers],
            ),
        },
    )

    return [
        DefaultInfo(
            executable = updater,
            runfiles = ctx.runfiles(files = specs + xcodeprojs + installers),
        ),
    ]

_update_fixtures = rule(
    implementation = _update_fixtures_impl,
    attrs = {
        "targets": attr.label_list(
            mandatory = True,
            providers = [XcodeProjOutputInfo],
        ),
        "_installer_template": attr.label(
            allow_single_file = True,
            executable = False,
            default = Label("//xcodeproj/internal:installer.template.sh"),
        ),
        "_updater_template": attr.label(
            allow_single_file = True,
            default = ":updater.template.sh",
        ),
    },
    executable = True,
)

def update_fixtures(**kwargs):
    testonly = kwargs.pop("testonly", True)
    _update_fixtures(
        testonly = testonly,
        **kwargs
    )

def xcodeproj_srcs():
    return native.glob(
        ["project.xcodeproj/**/*"],
        exclude = [
            "project.xcodeproj/xcshareddata/**/*",
            "project.xcodeproj/**/xcuserdata/**/*",
            "project.xcodeproj/*.xcuserdatad/**/*",
        ],
    )
