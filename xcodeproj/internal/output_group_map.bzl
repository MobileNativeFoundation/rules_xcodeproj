"""Module containing functions dealing with output group map files."""

# Each "file" might actually represent many files (if the "file" is an output
# directory). This value was optimized around indexstores. The larger this value
# is, the higher the memory use of the `XcodeProjOutputMap` action, and it
# forces more of the collection to happen at the end of the build, all at once.
# If this value is too small though, the overhead of too many actions slows
# things down. With a small enough value some actions will have to run
# sequentially, which lowers the concurrent burden.
# TODO: Use a different value for different types of outputs.
_SHARD_SIZE = 75

def _write_sharded_maps(*, ctx, name, files, toplevel_cache_buster):
    files_list = files.to_list()
    length = len(files_list)
    shard_count = length // _SHARD_SIZE
    if length % _SHARD_SIZE != 0:
        shard_count += 1

    if shard_count < 2:
        return [
            _write_sharded_map(
                ctx = ctx,
                name = name,
                shard = None,
                shard_count = 1,
                files = files,
                toplevel_cache_buster = toplevel_cache_buster,
            ),
        ]

    shards = []
    for shard in range(shard_count):
        sharded_inputs = depset(
            files_list[shard * _SHARD_SIZE:(shard + 1) * _SHARD_SIZE],
        )
        shards.append(
            _write_sharded_map(
                ctx = ctx,
                name = name,
                shard = shard + 1,
                shard_count = shard_count,
                files = sharded_inputs,
                toplevel_cache_buster = toplevel_cache_buster,
            ),
        )

    return shards

def _write_sharded_map(
        *,
        ctx,
        name,
        shard,
        shard_count,
        files,
        toplevel_cache_buster):
    args = ctx.actions.args()
    args.use_param_file("%s", use_always = True)
    args.set_param_file_format("multiline")
    args.add_all(files, expand_directories = False)

    if shard:
        output_path = "shards/{}-{}.filelist".format(name, shard)
        progress_message = """\
Generating output map (shard {} of {}) for '{}'""".format(
            shard,
            shard_count,
            name,
        )
    else:
        output_path = "{}.filelist".format(name)
        progress_message = "Generating output map for '{}'".format(name)

    output = ctx.actions.declare_file(output_path)

    ctx.actions.run_shell(
        command = """
if [[ $OSTYPE == darwin* ]]; then
  cp -c \"$1\" \"$2\"
else
  cp \"$1\" \"$2\"
fi
""",
        arguments = [
            args,
            output.path,
        ],
        # Include files as inputs to cause them to be built or downloaded,
        # even if they aren't top level targets
        inputs = depset(toplevel_cache_buster, transitive = [files]),
        mnemonic = "XcodeProjOutputMap",
        progress_message = progress_message,
        outputs = [output],
        execution_requirements = {
            # No need to cache, as it's super ephemeral
            "no-cache": "1",
            # No need for remote, as it takes no time, and we don't want the
            # remote executor to download all the inputs for nothing
            "no-remote": "1",
            # Disable sandboxing for speed
            "no-sandbox": "1",
        },
    )

    return output

def _write_map(*, ctx, name, files, toplevel_cache_buster):
    if files == None:
        files = depset()

    files_list = _write_sharded_maps(
        ctx = ctx,
        name = name,
        files = files,
        toplevel_cache_buster = toplevel_cache_buster,
    )
    if len(files_list) == 1:
        # If only one shared output map was generated, we use it as is
        return files_list[0]
    files = depset(files_list)

    args = ctx.actions.args()
    args.add_all(files)

    output = ctx.actions.declare_file(
        "{}.filelist".format(ctx.attr.name, name),
    )

    ctx.actions.run_shell(
        command = """
readonly output="$1"
shift
cat $@ > "$output"
""",
        arguments = [
            output.path,
            args,
        ],
        # Include files as inputs to cause them to be built or downloaded,
        # even if they aren't top level targets
        inputs = depset(toplevel_cache_buster, transitive = [files]),
        mnemonic = "XcodeProjOutputMapMerge",
        progress_message = "Merging {} output map".format(name),
        outputs = [output],
        execution_requirements = {
            # No need to cache, as it's super ephemeral
            "no-cache": "1",
            # No need for remote, as it takes no time, and we don't want the
            # remote executor to download all the inputs for nothing
            "no-remote": "1",
            # Disable sandboxing for speed
            "no-sandbox": "1",
        },
    )

    return output

output_group_map = struct(
    write_map = _write_map,
)
