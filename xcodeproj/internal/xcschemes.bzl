"""Module for defining custom Xcode schemes (`.xcscheme`s)."""

# Scheme

def _scheme(name, *, profile = "same_as_run", run = None, test = None):
    """Defines a custom scheme.

    Args:
        name: The name of the scheme.
        profile: A value returned by `xcschemes.profile`, or the string
            `"same_as_run"`. If `"same_as_run"`, the same targets will be built
            for the Profile action as are built for the Run action (defined by
            `xcschemes.run`). If `None`, `xcschemes.profile()` will be used,
            which means no targets will be built for the Profile action.
        run: A value returned by `xcschemes.run`. If `None`, `xcschemes.run()`
            will be used.
        test: A value returned by `xcschemes.test`. If `None`,
            `xcschemes.test()` will be used.
    """
    if not profile:
        profile = xcschemes.profile()
    if not run:
        run = xcschemes.run()
    if not test:
        test = xcschemes.test()

    return struct(
        name = name,
    )

# Actions

def _profile(*, launch_target = None, xcode_configuration = None):
    return struct()

def _run(
        *,
        build_targets = [],
        launch_target = None,
        xcode_configuration = None):
    return struct()

def _test(
        *,
        build_targets = [],
        tests = [],
        xcode_configuration = None):
    return struct()

# Targets

def _launch_target(
        label,
        *,
        extension_host = None,
        library_targets = [],
        post_actions = [],
        pre_actions = [],
        target_environment = None):
    if not label:
        fail("Label must be provided to `xcschemes.launch_target`.")

    return struct(
        label = label,
    )

def _library_target(label, *, post_actions = [], pre_actions = []):
    if not label:
        fail("Label must be provided to `xcschemes.library_target`.")

    return struct(
        label = label,
    )

def _test_target(
        label,
        *,
        enabled = True,
        library_targets = [],
        post_actions = [],
        pre_actions = [],
        target_environment = None):
    if not label:
        fail("Label must be provided to `xcschemes.test_target`.")

    return struct(
        label = label,
    )

def _top_level_build_target(
        label,
        *,
        extension_host = None,
        library_targets = [],
        target_environment = None):
    if not label:
        fail("Label must be provided to `xcschemes.top_level_build_target`.")

    return struct(
        label = label,
    )

def _top_level_build_target_anchor(
        label,
        *,
        extension_host = None,
        library_targets = [],
        target_environment = None):
    if not label:
        fail("Label must be provided to `xcscheme.top_level_build_target_anchor`.")

    return struct(
        label = label,
    )

# `pre_post_actions`

def _build_script(title, *, order = None, script_text):
    return struct(
        for_build = True,
        order = order,
        script_text = script_text,
        title = title,
    )

def _launch_script(title, *, order = None, script_text):
    return struct(
        for_build = False,
        order = order,
        script_text = script_text,
        title = title,
    )

_pre_post_actions = struct(
    build_script = _build_script,
    launch_script = _launch_script,
)

# `xcschemes`

xcschemes = struct(
    build_script_action = build_script_action,
    launch_target = _launch_target,
    library_target = _library_target,
    pre_post_actions = _pre_post_actions,
    profile = _profile,
    run = _run,
    scheme = _scheme,
    script_action = _script_action,
    test = _test,
    test_target = _test_target,
    top_level_build_target = _top_level_build_target,
    top_level_build_target_anchor = _top_level_build_target_anchor,
)
