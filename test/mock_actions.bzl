"""Module for a mocked `ctx.actions` struct."""

def _path_or_str(value):
    if hasattr(value, "path"):
        return value.path
    return str(value)

# API

def _create():
    run_args = {}

    def _action_run(*, arguments, inputs = [], outputs, **_kwargs):
        run_args["arguments"] = arguments
        run_args["inputs"] = inputs
        run_args["outputs"] = outputs

    declared_directories = {}

    def _actions_declare_directory(path):
        file = _mock_file(
            path = path,
        )
        declared_directories[file] = None
        return file

    declared_files = {}

    def _actions_declare_file(path):
        file = _mock_file(
            path = path,
        )
        declared_files[file] = None
        return file

    writes = {}

    def _actions_write(write_output, content):
        if type(content) == "string":
            writes[write_output.path] = content
        else:
            writes[write_output.path] = "\n".join(content.captured.args) + "\n"

    args_objects = []

    def _create_args():
        args = []

        def _inner_add_all(
                flag_or_values,
                values = None,
                *,
                format_each = None,
                map_each = None,
                omit_if_empty = True,
                terminate_with = None):
            inner_args = []

            if values != None:
                flag = flag_or_values
            else:
                flag = None
                values = flag_or_values

            if type(values) == "depset":
                values = values.to_list()

            if omit_if_empty and not values:
                return inner_args

            if flag:
                inner_args.append(flag)

            if map_each:
                for value in values:
                    mapped_value = map_each(value)
                    if type(mapped_value) == "list":
                        if format_each:
                            inner_args.extend(
                                [format_each % v for v in mapped_value],
                            )
                        else:
                            inner_args.extend(
                                [str(v) for v in mapped_value],
                            )
                    elif mapped_value:
                        if format_each:
                            inner_args.append(format_each % mapped_value)
                        else:
                            inner_args.append(str(mapped_value))
            else:
                inner_args.extend([_path_or_str(value) for value in values])

            if terminate_with != None:
                inner_args.append(terminate_with)

            return inner_args

        def _add_all(
                flag_or_values,
                values = None,
                *,
                format_each = None,
                map_each = None,
                omit_if_empty = True,
                terminate_with = None):
            args.extend(
                _inner_add_all(
                    flag_or_values,
                    values = values,
                    format_each = format_each,
                    map_each = map_each,
                    omit_if_empty = omit_if_empty,
                    terminate_with = terminate_with,
                ),
            )

        def _add_joined(
                flag_or_values,
                values = None,
                *,
                format_each = None,
                join_with,
                map_each = None,
                omit_if_empty = True,
                terminate_with = None):
            args.append(
                join_with.join(
                    _inner_add_all(
                        flag_or_values,
                        values = values,
                        format_each = format_each,
                        map_each = map_each,
                        omit_if_empty = omit_if_empty,
                        terminate_with = terminate_with,
                    ),
                ),
            )

        def _add(flag_or_value, value = None):
            if value != None:
                flag = flag_or_value
            else:
                flag = None
                value = flag_or_value

            if flag:
                args.append(flag)

            args.append(_path_or_str(value))

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
            add_joined = _add_joined,
            use_param_file = _args_use_param_file,
            set_param_file_format = _args_set_param_file_format,
        )

        args_objects.append(arg_object)

        return arg_object

    mock = struct(
        args = _create_args,
        declare_directory = _actions_declare_directory,
        declare_file = _actions_declare_file,
        run = _action_run,
        write = _actions_write,
    )

    return struct(
        args_objects = args_objects,
        run_args = run_args,
        declared_directories = declared_directories,
        declared_files = declared_files,
        mock = mock,
        writes = writes,
    )

def _mock_file(path):
    return struct(
        path = path,
    )

mock_actions = struct(
    create = _create,
    mock_file = _mock_file,
)
