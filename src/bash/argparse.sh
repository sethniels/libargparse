#!/bin/bash
#argparse.sh

## Get script name
AP_SCRIPT_BNAME=`basename ${BASH_SOURCE}`
if [ "${AP_SCRIPT_BNAME}" == "bash" ]; then
    AP_IS_SOURCED=1
    AP_SCRIPT_BNAME="argparse"
    ARCHSCRIPT_ARGS=("$0" "$@")
fi

# argparse constants
readonly AP_SUPPRESS="==SUPPRESS=="
readonly AP_OPTIONAL="?"
readonly AP_ZERO_OR_MORE="*"
readonly AP_ONE_OR_MORE="+"
readonly AP_PARSER="A..."
readonly AP_REMAINDER="..."
readonly AP__UNRECOGNIZED_ARGS_ATTR="_unrecognized_args"
readonly MAX_INDENT=24
readonly RIGHT_MARGIN=80

######################## main argparse functions ########################
ArgumentParser () {
    # @param parser_name: MUST be the first argument
    # @kwparam prog: the name of the program (default: to `basename $0`)
    # @kwparam usage: a usage message (default: generated based on arguments added)
    # @kwparam description: a description of what the program does (default: "")
    # @kwparam epilog: text following the argument descriptions (default: "")
    # @kwparam parents: parsers whose arguments should be copied into this one
    # @kwparam formatter_class: HelpFormatter class for printing help messages
    # @kwparam prefix_chars: characters that prefix optional arguments (default: "-")
    # @kwparam fromfile_prefix_chars: characters that prefix files containing additional arguments
    # @kwparam argument_default: the default value for all arguments (default: "")
    # @kwparam conflict_handler: string indicating how to handle conflicts
    # @kwparam add_help: add a -h/-help option (default: "true")

    # Set up parser names
    local parser_name="$1"
    shift
    is_valid_name "${parser_name}"
    assertReturn "ArgumentParser: invalid parser name: ${parser_name}"
    local posargs_name=AP_POSARGS_${parser_name}
    local optargs_name=AP_OPTARGS_${parser_name}

    # Set up parser map and lists
    # TODO: should clean these up a little more thoroughly
    unset ${parser_name} ${posargs_name} ${optargs_name}
    declare -gA ${parser_name}
    declare -ga ${posargs_name} ${optargs_name}

    declare -n curr_parser=${parser_name}
    curr_parser[posargs]=${posargs_name}
    curr_parser[optargs]=${optargs_name}
    curr_parser[formatter_class]=HelpFormatter
    curr_parser[prefix_chars]="-"
    curr_parser[conflict_handler]="error"
    curr_parser[add_help]="true"
    curr_parser[convert_arg_line_func]=convert_arg_line_to_args

    # Parse ArgumentParser args
    local key
    while [ "$#" -gt 0 ]; do
        curr_input="$1"
        case "${curr_input}" in
            # Fallthrough is intentional
            prog=*|usage=*|description=*|epilog=*|version=*) ;&
            parents=*|formatter_class=*|prefix_chars=*) ;&
            fromfile_prefix_chars=*|argument_default=*) ;&
            conflict_handler=*|add_help=*)
                key=${curr_input%=*}
                curr_parser[${key}]=${curr_input#*=}
                ;;
            *)
                false; assertReturn "ArgumentParser: unexpected argument: ${curr_input%=*}"
                ;;
        esac
        shift
    done

    if [ -z "${curr_parser[prog]}" ]; then
        curr_parser[prog]="${ARCHSCRIPT_ARGS[0]}"
    fi

    def_prefix="${curr_parser[prefix_chars]:0:1}"
    if is_true "${curr_parser[add_help]}"; then
        add_argument ${parser_name} "${def_prefix}h"\
            "${def_prefix}${def_prefix}help" action="help"\
            default="${AP_SUPPRESS}"\
            help="show this help message and exit"
    fi
    if [ ! -z "${curr_parser[version]}"]; then
        print_warning "The \"version\" argument to ArgumentParser is "\
            "deprecated. Please use \"add_argument(..., action='version', "\
            "version=\"N\", ...)\" instead"
        add_argument ${parser_name} "${def_prefix}+v"\
            "${def_prefix}${def_prefix}version" --action="version"\
            --default="${AP_SUPPRESS}" --version="${curr_parser[version]}"\
            --help="show program's version number and exit"
    fi
}

add_argument () {
    # @param parser_name: MUST be the first argument; is the value set by ArgumentParser
    # @param name or flags: a name or a list of option strings
    # @param action: an action string indicating what is to be done when this argument is provided
    # @param nargs: number of command line args to be consumed
    # @param const: a constant value required by ceratain actions or nargs
    # @param default: a default value used if the argument is not provided
    # @param type: the type to which the command line arg will be converted
    # @param choices: a discrete comma-separated list of allowed values that the argment may assume
    # @param required: whether or not an optional argument may be ommitted
    # @param help: a description of the argument is used for
    # @param metavar:  a name for the argument in usage messages
    # @param dest: the name of the variable that will be created for this argument

    # Create local variables
    local parser_name="$1"
    shift
    is_valid_name "${parser_name}"
    assertReturn "add_argument: invalid parser name: ${parser_name}"

    declare -n curr_parser="${parser_name}"
    [ "${#curr_parser[@]}" -gt 0 ]
    assertReturn "add_argument: ${parser_name} is not a valid parser"

    declare -A curr_arg
    local key
    local prev_arg
    local curr_names=()

    # Parse all inputs
    while [ $# -gt 0 ]; do
        curr_input=$1
        case "${curr_input}" in
            action|nargs|const|default|type|required|help|metavar|dest)
                if [ -z "${2}" ] || [[ "${2}" == -* ]]; then
                    curr_names+=(--${curr_input})
                else
                    curr_arg[${curr_input}]=${2}
                    shift
                fi
                ;;
            # Fallthrough is intentional
            action=*|nargs=*|const=*|default=*|type=*|required=*) ;&
            help=*|metavar=*|dest)
                key=${curr_input%=*}
                curr_arg[${key}]=${curr_input#*=}
                ;;
            choices)
                unset temp_choices
                IFS="," read -ra temp_choices <<< "${2}"
                shift
                ;;
            choices=*)
                unset temp_choices
                IFS="," read -ra temp_choices <<< "${2#=*}"
                ;;
            *)
                curr_names+=("${curr_input}") ;;
        esac
        shift
    done

    # Distinguish between positional and optional arguments
    local option_strings=()
    local chars="${curr_parser[prefix_chars]}"
    if [ "${#curr_names[@]}" == 0 ] || ([ "${#curr_names[@]}" == 1 ] &&\
            ! find_in "${curr_names[0]:0:1}" "${chars}"); then
        # This is a positional argument
        [ "${#curr_names[@]}" != 0 ] || [ -z "${curr_arg[dest]}" ]
        assertReturn "dest supplied twice for positional argument"

        # make sure required is not specified
        [ -z "${curr_arg[required]}" ]
        assertReturn "'required' is an invalid argument for positionals"

        # mark positional arguments as required if at least one is
        # always required
        if ! find_in "${curr_arg[nargs]}" AP_OPTIONAL AP_ZERO_OR_MORE; then
            curr_arg[required]=True
        fi
        if [ "${curr_arg[nargs]}" == "${AP_ZERO_OR_MORE}" ] &&\
            [ -z "${curr_arg[default]}" ]; then
            curr_arg[required]=True
        fi

        if [ -z "${curr_arg[dest]}" ]; then
            curr_arg[dest]="${curr_names[0]}"
        fi
        unset curr_names[0]
        args_list_name="${curr_parser[posargs]}"
    else
        # This is an optional argument
        # error on strings that don't start with an appropriate prefix
        local long_option_string
        for option_string in "${curr_names[@]}"; do
            find_in "${option_string:0:1}" "${chars}"
            assertReturn "invalid option string '${option_string}': must start"\
                "with a character '${chars}'"

            # strings starting with two prefix characters are long options
            option_strings+=("${option_string}")
            if find_in "${option_string:0:1}" "${chars}" &&\
                [ "${#option_string}" -gt 1 ] &&\
                    find_in "${option_string:1:1}" "${chars}" &&\
                        [ -z "${long_option_string}" ]; then
                long_option_string="${option_string}"
            fi
        done

        # infer destination, '--foo-bar' -> 'foo_bar' and '-x' -> 'x'
        local dest="${curr_arg[dest]}" 
        if [ -z "${dest}" ]; then
            local dest_option_string="${option_strings[0]}"
            if [ ! -z "${long_option_strings}" ]; then
                dest_option_string="${long_option_string}"
            fi
            dest="${dest_option_string}"
            local prefix="${dest:0:1}"
            dest="`echo ${dest} | sed \"s/^${prefix}*//\"`"
            curr_arg[dest]=
            [ ! -z "${dest}" ]
            assertReturn "dest= is required for options like '${option_string}'"
            curr_arg[dest]="${dest}"
        fi

        # Make sure there is no option string conflicts
        check_duplicate_optstr "${parser_name}" "${curr_names[@]}"

        args_list_name="${curr_parser[optargs]}"
    fi
    
    # Determine the action
    local action="${curr_arg[action]}"
    if [ -z "${action}" ]; then
        action=store
    fi
    case "${action}" in
        store|append)
            if [ "${action}" == store ]; then
                errmsg=("nargs for store actions must be > 0; if you" \
                    "have nothing to store, actions such as store" \
                    "true or store const may be more appropriate")
            else
                errmsg=("nargs for append actions must be > 0; if arg strings" \
                    "are not supplying the value to append, the append const" \
                    "action may be more appropriate")
            fi
            [ "${curr_arg[nargs]}" != 0 ]
            assertReturn "${errmsg[@]}"

            [ -z "${curr_arg[const]}" ] ||\
                [ "${curr_arg[nargs]}" == "${AP_OPTIONAL}" ]
            assertReturn "nargs must be '${AP_OPTIONAL}' to supply const"
            ;;
        store_const|store_true|store_false|append_const|count|help|version)
            req_params=()
            bad_params=(nargs choices)
            if [ "${action}" == store_const ]; then
                req_params+=(const)
            elif [ "${action}" == append_const ]; then
                req_params+=(const)
                bad_params+=(default)
            elif [ "${action}" == count ]; then
                bad_params+=(const type)
                if [ ! -z "${curr_arg[default]}" ]; then
                    is_integer "${curr_arg[default]}" 
                    assertReturn "for action 'count', default must be an"\
                        "integer"
                fi
            else
                bad_params+=(const)
                if [ -z "${curr_arg[default]}" ]; then
                    if [ "${action}" == store_true ]; then
                        curr_arg[default]="False"
                    else
                        curr_arg[default]="True"
                    fi
                fi
            fi

            if [ "${action}" == version ]; then
                req_params+=(version)
            else
                bad_params+=(version)
            fi

            for param in "${req_params[@]}"; do
                [ ! -z "${curr_arg[${param}]}" ]
                assertReturn "action '${action}' requires '${param}'"
            done

            for param in "${bad_params[@]}"; do
                [ -z "${curr_arg[${param}]}" ]
                assertReturn "got an unexpected keyword argument '${param}'"
            done
            curr_arg[nargs]=0
            ;;
        *)
            false; assertReturn "unknown action \"${action}\"" ;;
    esac

    # Replace - with _ in dest and check name validity
    curr_arg[dest]=${curr_arg[dest]//-/_}
    is_valid_name "${curr_arg[dest]}"
    assertReturn "variable names cannot start with a digit and may only"\
        "contain alphanumeric characters and underscores (_): ${curr_arg[dest]}"

    # Create a global arg variable and add to the appropriate list
    declare -n args_list=${args_list_name}
    arg_ind=${#args_list[@]}
    arg_var_name=${args_list_name}${arg_ind}
    unset ${arg_var_name}
    declare -Ag ${arg_var_name}
    declare -n arg_var=${arg_var_name}
    args_list[${arg_ind}]=${arg_var_name}
    eval "${arg_var_name}=`print_map curr_arg`"

    # Create a list of OPTS strings
    opt_strings_name=${arg_var_name}_OPTSTRS
    unset ${opt_strings_name}
    declare -ag ${opt_strings_name}
    declare -n opt_strings=${opt_strings_name}
    opt_strings=("${option_strings[@]}")
    arg_var[optstrs]=${opt_strings_name}
}

parse_args () {
    # @param parser_name: MUST be the first argument; is the value set by ArgumentParser
    # @param namespace_name: MUST be the second argument; is the name of the namespace that will contain the parsed arguments. If it is an empty string, parsed arguments will be set in the global scope (AP_GLOBAL_NS).
    # @params: all remaining parameters will be parsed and assigned in the given namespace. If left blank then the command line argument will be used (i.e. $@)

    # Create local variables
    local parser_name="$1"
    local namespace_name="$2"
    shift 2
    if [ -z "${namespace_name}" ]; then
        namespace_name=AP_GLOBAL_NS
    fi
    local argv
    parse_known_args "${parser_name}" "${namespace_name}" argv "$@"

    [ "${#argv[@]}" -le 0 ]
    assertReturn "unrecognized arguments: ${argv[@]}"
}

parse_known_args () {
    # Similar to parse_args; however, will not raise an error if any arguments are left unparsed
    # @param parser_name: MUST be the first argument; is the value set by ArgumentParser
    # @param namespace_name: MUST be the second argument; is the name of the namespace that will contain the parsed arguments. If it is an empty string, parsed arguments will be set in the global scope (AP_GLOBAL_NS).
    # @param argv_name: MUST be the third argument; is the name of the array that will contain any unparsed arguments
    # @params: all remaining parameters will be parsed and assigned in the given namespace. If left blank then the command line argument will be used (i.e. $@)

    # Create local variables
    local parser_name="$1"
    is_valid_name "${parser_name}"
    assertReturn "parse_known_args: invalid parser name: ${parser_name}"

    declare -n curr_parser="${parser_name}"
    [ "${#curr_parser[@]}" -gt 0 ]
    assertReturn "parse_known_args: ${parser_name} is not a valid parser"

    local namespace_name="$2"
    if [ -z "${namespace_name}" ]; then
        namespace_name=AP_GLOBAL_NS
    fi
    is_valid_name "${namespace_name}"
    assertReturn "parse_known_args: invalid namespace name: ${namespace_name}"

    local argv_name="$3"
    is_valid_name "${argv_name}"
    assertReturn "parse_known_args: invalid argv name: ${argv_name}"

    shift 3

    unset ${namespace_name}
    declare -Ag ${namespace_name}
    declare -n curr_ns="${namespace_name}"
    declare -n argv_loc=${argv_name}
    argv_loc=()

    local posargs_name="${curr_parser[posargs]}"
    local optargs_name="${curr_parser[optargs]}"
    declare -n posargs="${posargs_name}"
    declare -n optargs="${optargs_name}"
    local curr_input arg_name action opt_arg_found

    # Set any default values
    local allargs=("${posargs[@]}")
    allargs+=("${optargs[@]}")
    for arg_name in "${allargs[@]}"; do
        declare -n arg=${arg_name}
        if [ ! -z "${arg[default]}" ]; then
            curr_ns[${arg[dest]}]="${arg[default]}"
        fi
    done

    # replace arg strings that are file references
    local input_args=("$@")
    if [ ! -z "${curr_parser[fromfile_prefix_chars]}" ]; then
        _read_args_from_files ${parser_name} input_args "${input_args[@]}"
    fi

    # Parse arguments
    local unrecognized_opts=()
    local posarg_i=0
    local num_posargs="${#posargs[@]}"
    while [ "${#input_args[@]}" -gt 0 ]; do
        if [ -z "${curr_input}" ]; then
            curr_input="${input_args[0]}"
        fi

        # Check for positional arguments
        local chars="${curr_parser[prefix_chars]}"
        echo "DEBUG: curr_input=${curr_input}"
        echo "DEBUG: chars=${chars}"
        if ! find_in "${curr_input:0:1}" "${chars}"; then
            arg_name="${posargs[${posarg_i}]}"
            assertReturn "DEBUG: arg_name=${arg_name}"
            handle_action ${arg_name} ${namespace_name} input_args
        else
            opt_arg_found=0
            # Check for optional arguments
            for arg_name in "${optargs[@]}"; do
                optstr=`find_optionstring ${arg_name} "${curr_input}" "${chars}"`
                if [ -z "${opstr}" ]; then
                    continue
                fi

                # Handle the action
                handle_opt_action ${arg_name} ${namespace_name} input_args ${optstr}
                opt_arg_found=1
                break
            done
            if [ "${opt_arg_found}" != 1 ]; then
                unrecognized_opts+=("${curr_input}")
                curr_input=""
                input_args=("${input_args[@]:1}")
            fi
        fi
    done

}

print_help () {
    # @param parser_name: MUST be the first argument; is the value set by ArgumentParser

    # Create local variables
    local parser_name="$1"
    shift
    is_valid_name "${parser_name}"
    assertReturn "print_help: invalid parser name: ${parser_name}"

    declare -n curr_parser="${parser_name}"
    [ "${#curr_parser[@]}" -gt 0 ]
    assertReturn "print_help: ${parser_name} is not a valid parser"

    local posargs_name="${curr_parser[posargs]}"
    local optargs_name="${curr_parser[optargs]}"
    declare -n posargs="${posargs_name}"
    declare -n optargs="${optargs_name}"

    local prog="${curr_parser[prog]}"
    if [ -z "${prog}" ]; then
        prog="`basename $0`"
    fi
    local help_str="usage: "

    # Print brief help
    if [ -z "${curr_parser[usage]}" ]; then
        help_str+="${prog}"
        for arg in "${optargs[@]}"; do
            help_str+=" `print_arg_help -b ${arg}`"
        done
        for arg in "${posargs[@]}"; do
            help_str+=" `print_arg_help -b ${arg}`"
        done
    else
        help_str+="${curr_parser[usage]}"
    fi
    help_str+="\n\n"

    # Add description
    if [ ! -z "${curr_parser[description]}" ]; then
        help_str+="${curr_parser[description]}"
        help_str+="\n\n"
    fi

    # Determine indentation
    local indent=0
    local tmp_str
    local margin=${RIGHT_MARGIN}
    for arg in "${posargs[@]}"; do
        tmp_str="`print_arg_help -h ${arg}`"
        if [ "${#tmp_str}" -gt ${indent} ]; then
            indent="${#tmp_str}" 
        fi
    done
    for arg in "${optargs[@]}"; do
        tmp_str="`print_arg_help -h ${arg}`"
        if [ "${#tmp_str}" -gt ${indent} ]; then
            indent="${#tmp_str}" 
        fi
    done
    ((indent+=2))
    if [ ${indent} -gt ${MAX_INDENT} ]; then
        indent=${MAX_INDENT}
    fi

    # Print full help
    if [ "${#posargs[@]}" -gt 0 ]; then
        help_str+="positional arguments:\n"
        for arg in "${posargs[@]}"; do
            help_str+="`print_arg_help -f -i ${indent} -m ${margin} ${arg}`\n"
        done
        help_str="${help_str%\\n}"
        help_str+="\n\n"
    fi
    if [ "${#optargs[@]}" -gt 0 ]; then
        help_str+="optional arguments:\n"
        for arg in "${optargs[@]}"; do
            help_str+="`print_arg_help -f -i ${indent} -m ${margin} ${arg}`\n"
        done
        help_str="${help_str%\\n}"
    fi

    # Print epilog
    if [ ! -z "${curr_parser[epilog]}" ]; then
        help_str+="\n\n"
        help_str+="${curr_parser[epilog]}"
    fi

    # Perform string substitution
    help_str="${help_str//%(prog)/${prog}}"

    echo -e "${help_str}"
}

######################## Auxiliary functions ########################
assertReturn () {
    # Use after a command to confirm that it returned with no errors;
    # otherwise, print an error message and exit the script
    local retval=$?
    local errmsg="$@"
    if [ "${retval}" != "0" ]; then
        echo "ERROR: ${errmsg}"
        exit 1
    fi
}

check_duplicate_optstr () {
    # Checks the option strings for all options for duplicate option strings
    # @param parser_name: MUST be the first argument; is the value set by ArgumentParser
    # @params curr_optstr: a list of options strings to check against the
    #   current optional arguments

    # Local variables
    local parser_name="$1"
    shift
    local curr_optstr="$@"
    declare -n curr_parser="${parser_name}"
    local optargs_name="${curr_parser[optargs]}"
    declare -n optargs="${optargs_name}"

    # Loop over current optargs
    local arg_name ostr costr
    for arg_name in "${optargs[@]}"; do
        declare -n arg="${arg_name}"
        optstrs_name=${arg[optstrs]}
        declare -n optstrs=${optstrs_name}
        for ostr in "${optstrs[@]}"; do
            for costr in "${curr_optstr[@]}"; do
                if [ "${ostr}" == "${costr}" ]; then
                    all_ostrs="${opstrs[@]}"
                    all_ostrs="${all_ostrs// /\/}"
                    false
                    assertReturn "argument ${all_ostrs}: conflicting option string(s): ${costr}"
                fi
            done
        done
    done
    
    return 0
}

print_arg_help () {
    # Prints the brief, half or full help message for the given argument map.
    #   Only one flag may be given at a time
    # @flag -b: runs in "brief" mode, i.e. only one option string, no help
    # @flag -h: runs in "half" mode, i.e. all option strings, no help
    # @flag -f: runs in "full" mode, i.e. all option strings plus help
    # @opt -m: set the length of the right margin
    # @opt -i: set the length of the left indentation

    # Get options
    local brief=0
    local half=0
    local full=0
    local margin=${RIGHT_MARGIN}
    local indent=${MAX_INDENT}
    while [ "$#" -gt 0 ]; do
        while getopts "bhfm:i:" opt; do
            case "${opt}" in
                b) brief=1 ;;
                h) half=1 ;;
                f) full=1 ;;
                m) margin=${OPTARG} ;;
                i) indent=${OPTARG} ;;
                *) false; assertReturn "print_arg_help: no such flag ${opt}" ;;
            esac
        done
        shift $((OPTIND-1))
        if [ -z "${arg_obj_name}" ]; then
            arg_obj_name="$1"
        fi
        shift
    done
    [ $((brief+half+full)) -gt 0 ]
    assertReturn "print_arg_help: must provide a mode flag: -b, -h, -f"
    [ $((brief+half+full)) -le 1 ]
    assertReturn "print_arg_help: must provide only one mode flag"

    # Set up variables
    declare -n arg_obj="${arg_obj_name}"
    declare -n optionstrings="${arg_obj[optstrs]}"
    local metavar
    local action=${arg_obj[action]}
    local nargs=${arg_obj[nargs]}
    case "${action}" in
        "") ;&
        store)
            metavar="${arg_obj[metavar]}"
            if [ -z "${metavar}" ]; then
                metavar="${arg_obj[dest]^^}"
            fi
            if [ "${nargs}" == "?" ]; then
                metavar="[${metavar}]"
            elif [ "${nargs}" == "+" ]; then
                metavar="[${metavar,,} ...]"
            fi
            metavar=" ${metavar}"
            ;;
        *) ;;
    esac

    # Build the brief or full help string
    local help_str=""
    if [ "${brief}" == "1" ]; then
        if [ "${#optionstrings[@]}" -gt 0 ]; then
            help_str+="[${optionstrings[0]}${metavar}]"
        else
            help_str+="${arg_obj[dest]}${metavar}"
        fi
    else
        help_str+="  "
        if [ "${#optionstrings[@]}" -gt 0 ]; then
            for optstr in "${optionstrings[@]}"; do
                help_str+="${optstr}${metavar}, "
            done
            help_str="${help_str%, }"
        else
            help_str+="${arg_obj[dest]}"
        fi

        # Add help message if in full mode
        if [ "${full}" == "1" ]; then
            help_len=${#help_str}
            if [ "$((help_len+2))" -gt ${indent} ]; then
                help_str+="\n"
            else
                local indent_shift=$((indent-help_len))
                for i in `seq 1 ${indent_shift}`; do
                    help_str+=" "
                done
            fi
            help_str+="${arg_obj[help]}"
        fi
    fi

    echo "${help_str}"
}

format_help_str () {
    local oldstr="$1"
    local margin="$2"
    local indent="$3"

    if [ -z "${margin}" ]; then
        margin=0
    fi
    if [ -z "${indent}" ]; then
        indent=0
    fi
    newstr=""
    while [ "${#oldstr}" -gt "${margin}" ]; do
        i=$((margin+1))
        while [ "${oldstr:${i}:1}" != " " ] && [ "${i}"
            -ge 0 ]; do
            ((i--))
        done
        newstr+="${oldstr:0:${i}}\n"
        oldstr="${oldstr:$((i+1))}"
    done
    newstr+="${oldstr}"
    echo "${newstr}"
}

print_map () {
    # Prints a map (associative array) such that it can be used to initialize
    # another array with the same output
    mapname=$1
    declare -n currmap=${mapname}
    print_str="("
    for k in "${!currmap[@]}"; do
        print_str+="[${k}]=\"${currmap[${k}]}\" "
    done
    print_str+=")"
    echo "${print_str}"
}

print_array () {
    # Prints an array such that it can be used to initialize another array with
    # the same output
    listname=$1
    declare -n currlist=${listname}
    print_str="("
    for v in "${currlist[@]}"; do
        print_str+="\"${v}\" "
    done
    print_str+=")"
    echo "${print_str}"
}

is_true () {
    # Checks input string for variations of "true"
    [[ "$1" =~ (TRUE|true|True|1) ]]
}

is_false () {
    # Checks input string for variations of "false"
    [[ "$1" =~ (FALSE|false|False|0) ]]
}

is_integer () {
    # Checks that the input is an integer
    int_ut="$1"
    [[ "${int_ut}" =~ ^-?[0-9]+$ ]]
}

is_valid_name () {
    # Checks that the input is a valid variable name, i.e. only alphanumeric and
    # underscores, but can't start with a digit
    local name_under_test="$1"
    [[ "${name_under_test}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}

find_in () {
    # Find a substring in another string or find an exact string in an array
    # of strings
    #
    # @param item: the string to look for
    # @param items: the string or array in which to look for item
    # @return: 0 if found or 1 if not
    local item="$1"
    shift
    local items=("$@")
    if [ "${#items[@]}" -eq 1 ]; then
        # Treat it as a single string
        if [[ "${items[0]}" =~ "${item}" ]]; then
            return 0
        fi
    else
        # Find it in the array
        local i
        for i in "${items[@]}"; do
            if [ "${i}" == "${item}" ]; then
                return 0
            fi
        done
    fi

    return 1
}

find_optionstring () {
    local arg_name="$1"
    local curr_input="$2"
    local prefixes="$3"

    declare -n arg="${arg_name}"
    declare -n optstrs="${arg[optstrs]}"
    local action="${arg[action]}"
    local nargs="${arg[nargs]}"
    local found=0
    local prefix=${curr_input:0:1}
    for ostr in "${optstrs[@]}"; do
        if [ "${curr_input}" == "${ostr}" ]; then
            # Exact match
            found=1
        elif [[ "${curr_input}" == "${ostr}=*" ]]; then
            # Match with explicit argument
            [ "${nargs}" != 0 ]
            assertReturn "error: argument ${ostr}: ignored"\
                "explicit argument '${curr_input#*=}'"
            found=1
        elif [[ ! "${ostr}" == "${prefix}${prefix}"* ]] && [[ "${ostr}" == "${prefix}"* ]] &&\
                [[ "${curr_input}" == "${ostr}"* ]]; then
            found=1
        fi
        
        if [ "${found}" == 1 ]; then
            echo "${ostr}"
            return 0
        fi
    done

    # If we reach this point, this is an unrecognized option
    return 1
}

handle_action () {
    local arg_name="$1"
    local namespace_name="$2"
    local rem_inputs_name="$3"

    declare -n arg=${arg_name}
    declare -n namespace=${namespace_name}
    declare -n rem_inputs=${rem_inputs_name}


}

handle_opt_action () {
    local arg_name="$1"
    local namespace_name="$2"
    local rem_inputs_name="$3"
    local optstr="$4"

    declare -n arg=${arg_name}
    declare -n namespace=${namespace_name}
    declare -n rem_inputs=${rem_inputs_name}

    # Determine if this is a long opt
    local curr_input="${rem_inputs[0]}"
    local prefix=${curr_input:0:1}
    if [ "${curr_input:1:1}" == "${prefix}" ]; then
        local is_long_opt=1
    fi

    # Strip the option flag and '='
    curr_input="${curr_input#${optstr}}"
    curr_input="${curr_input#=}"

    # Resolve the action type
    local action="${arg[action]}"
    local nargs="${arg[nargs]}"
    local dest=${arg[dest]}
    case "${action}" in
        store)
            if [ -z "${nargs}" ]; then
                if [ -z "${curr_input}" ]; then
                    rem_inputs="${rem_inputs[@]:1}"
                    curr_input="${rem_inputs[0]}"
                fi
                namespace[${dest}]="${curr_input}"
                rem_inputs="${rem_inputs[@]:1}"
            fi

            ;;
    esac

}

_read_args_from_files () {
    local parser_name="$1"
    declare -n curr_parser=${parser_name}
    local args_name="$2"
    declare -n args="${args_name}"
    shift 2

    declare -a arg_string
    local arg_strings=("$@")
    local new_args=()
    local fromfile_prefix="${curr_parser[fromfile_prefix_chars]}"
    for arg_string in "${arg_strings}"; do
        if [ -z "${arg_string}" ] ||\
            ! find_in "${arg_string:0:1}" "${fromfile_prefix}"; then
            new_args+=("${arg_string}")
        else
            local args_file="${arg_string:1}"
            local convert_arg_line_func=${curr_parser[convert_arg_line_func]}
            local arg_lines arg_line args_from_line arg
            [ -f "${args_file}" ]
            assertReturn "${args_file} is not a valid file"
            readarray -t arg_lines < "${args_file}"
            for arg_line in "${arg_lines[@]}"; do
                ${convert_arg_line_func} args_from_line "${arg_line}"
                declare -a arg_strs
                _read_args_from_files ${parser_name} arg_strs "${args_from_line[@]}"
                new_args+=("${arg_strs[@]}")
            done
        fi
    done

    args=("${new_args[@]}")
}

convert_arg_line_to_args () {
    # This is the default behavior; one line is one arg
    declare -n retarr="$1"
    shift
    retarr=("$@")
}

convert_arg_line_to_multiple_args () {
    # This splits each line by white space
    declare -n retarr="$1"
    shift
    eval "retarr=($@)"
}

