"""
Example rule that creates a directory containing localizable resources intended to be bundled with other app resources 
"""

def _localizable_resources_impl(ctx):
    localizable_directory = ctx.actions.declare_directory(ctx.attr.localizable_directory_name)

    ctx.actions.run_shell(
        progress_message = "Generating localizable resources...",
        command = """
localizable_directory=$1
localizable_strings_path="${localizable_directory}/Localizable.strings"
additional_localizable_strings_path="${localizable_directory}/AdditionalLocalizable.strings"

echo "\"rules_xcodeproj_key\" = \"rules_xcodeproj\";\n" > "${localizable_strings_path}"
echo "\"additional_rules_xcodeproj_key\" = \"additional_rules_xcodeproj_key\";\n" > "${additional_localizable_strings_path}"
""",
        arguments = [localizable_directory.path],
        inputs = [],
        outputs = [localizable_directory],
    )

    output_directory = ctx.actions.declare_directory("{}Output".format(ctx.attr.name))    
    ctx.actions.run_shell(
        progress_message = "Staging output container: '{}'".format(ctx.attr.localizable_directory_name),
        outputs = [output_directory],
        inputs = [localizable_directory],
        arguments = [localizable_directory.path, output_directory.path],
        command = "cp -r $1 $2",
    )

    return DefaultInfo(files = depset([output_directory]))
    
localizable_resources = rule(
    implementation = _localizable_resources_impl,
    attrs = {
        "localizable_directory_name": attr.string(doc = "Name of localizable directory intended to ultimately land in the app bundle, typically this will be something like fr.lproj"),
    },
)