# `selected_model_versions` file generator

The `selected_model_versions` generator creates a file that contains a JSON
representation of `[BazelPath: String]`, mapping `.xcdatamodeld` file paths to
selected `.xcdatamodel` file names. The output file is used by the
[`files_and_groups`](../files_and_groups/README.md) generator.
