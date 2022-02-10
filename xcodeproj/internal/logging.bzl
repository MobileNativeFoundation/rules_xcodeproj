"""Logging utility functions."""

def _colorize(text, color):
    """Applies ANSI color codes around the given text."""
    return "\033[1;{color}m{text}{reset}".format(
        color = color,
        reset = "\033[0m",
        text = text,
    )

def green(text):
    """Applies the ANSI color code for green around the given text."""
    return _colorize(text, "32")

def yellow(text):
    """Applies the ANSI color code for yellow around the given text."""
    return _colorize(text, "33")

def warn(msg):
    """Outputs a warning message."""

    # buildifier: disable=print
    print("\n{prefix} {msg}\n".format(
        msg = msg,
        prefix = yellow("WARNING:"),
    ))
