"""Logging utility functions."""

def _colorize(text, color, *, bold):
    """Applies ANSI color codes around the given text."""
    return "\033[{modifier};{color}m{text}{reset}".format(
        color = color,
        modifier = "1" if bold else "0",
        reset = "\033[0m",
        text = text,
    )

def green(text, *, bold):
    """Applies the ANSI color code for green around the given text."""
    return _colorize(text, "32", bold = bold)

def magenta(text, *, bold):
    """Applies the ANSI color code for magenta around the given text."""
    return _colorize(text, "35", bold = bold)

def yellow(text, *, bold):
    """Applies the ANSI color code for yellow around the given text."""
    return _colorize(text, "33", bold = bold)

def warn(msg):
    """Outputs a warning message."""

    # buildifier: disable=print
    print("\n{prefix} {msg}\n".format(
        msg = msg,
        prefix = magenta("WARNING:", bold = False),
    ))
