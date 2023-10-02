"""Module for a mocked `ctx.actions` struct."""

# API

def _create():
    run_args = {}

    def _action_run(*, arguments, inputs = [], outputs, **_kwargs):
        run_args["arguments"] = arguments
        run_args["inputs"] = inputs
        run_args["outputs"] = outputs

    declared_files = {}

    def _actions_declare_file(path):
        declared_files[path] = None
        return path

    writes = {}

    def _actions_write(write_output, content):
        if type(content) == "string":
            writes[write_output] = content
        else:
            writes[write_output] = "\n".join(content.captured.args) + "\n"

    args_objects = []

    def _create_args():
        args = []

        def _add_all(
                flag_or_values,
                values = None,
                *,
                map_each = None,
                omit_if_empty = True,
                terminate_with = None):
            if values != None:
                flag = flag_or_values
            else:
                flag = None
                values = flag_or_values

            if type(values) == "depset":
                values = values.to_list()

            if omit_if_empty and not values:
                return

            if flag:
                args.append(flag)

            if map_each:
                for value in values:
                    mapped_value = map_each(value)
                    if type(mapped_value) == "list":
                        args.extend(
                            [str(v) for v in mapped_value],
                        )
                    elif mapped_value:
                        args.append(str(mapped_value))
            else:
                args.extend([str(value) for value in values])

            if terminate_with != None:
                args.append(terminate_with)

        def _add(flag_or_value, value = None):
            if value != None:
                flag = flag_or_value
            else:
                flag = None
                value = flag_or_value

            if flag:
                args.append(flag)

            args.append(str(value))

        use_param_file_args = {}

        def _args_use_param_file(param_file):
            use_param_file_args["use_param_file"] = param_file

        set_param_file_format_args = {}

        def _args_set_param_file_format(format):
            set_param_file_format_args["format"] = format

        arg_object = struct(
            captured = struct(
                args = args,
                set_param_file_format_args = set_param_file_format_args,
                use_param_file_args = use_param_file_args,
            ),
            add = _add,
            add_all = _add_all,
            use_param_file = _args_use_param_file,
            set_param_file_format = _args_set_param_file_format,
        )

        args_objects.append(arg_object)

        return arg_object

    mock = struct(
        args = _create_args,
        declare_file = _actions_declare_file,
        run = _action_run,
        write = _actions_write,
    )

    return struct(
        args_objects = args_objects,
        run_args = run_args,
        declared_files = declared_files,
        mock = mock,
        writes = writes,
    )

mock_actions = struct(
    create = _create,
)
