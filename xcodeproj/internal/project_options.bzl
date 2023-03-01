"Functions for specifying project options to use with the `xcodeproj` macro."

def project_options(
        *,
        development_region = "en",
        indent_width = None,
        organization_name = None,
        tab_width = None,
        uses_tabs = None):
    """Project options for use in `xcodeproj.project_options`.

    Args:
        development_region: Optional. The development region for the project.
            Defaults to `"en"`.
        indent_width: Optional. The number of spaces to use for indentation.
        organization_name: Optional. Populates the `ORGANIZATIONNAME` attribute
            for the project.
        tab_width: Optional. The number of spaces to use for tabs.
        uses_tabs: Optional. Whether to use tabs for indentation.

    Returns:
        A `struct` containing fields for the provided arguments.
    """
    if not development_region:
        fail("`project_options.development_region` must be specified")

    d = {
        "development_region": development_region,
    }

    if indent_width:
        d["indent_width"] = str(indent_width)
    if organization_name:
        d["organization_name"] = organization_name
    if tab_width:
        d["tab_width"] = str(tab_width)
    if uses_tabs != None:
        d["uses_tabs"] = "1" if uses_tabs else "0"

    return d

def project_options_to_dto(project_options):
    """Converts a `project_options` struct to a DTO.

    Args:
        project_options: A value returned by `project_options`.

    Returns:
        A `dict` containing the fields of the provided `project_options` struct.
    """
    dto = {}

    development_region = project_options.get("development_region")
    if development_region and development_region != "en":
        dto["d"] = development_region

    indent_width = project_options.get("indent_width")
    if indent_width:
        dto["i"] = int(indent_width)

    organization_name = project_options.get("organization_name")
    if organization_name:
        dto["o"] = organization_name

    tab_width = project_options.get("tab_width")
    if tab_width:
        dto["t"] = int(tab_width)

    uses_tabs = project_options.get("uses_tabs")
    if uses_tabs:
        dto["u"] = uses_tabs == "1"

    return dto
