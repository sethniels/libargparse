#!/bin/bash
#argparse.sh

## Get script name
#AP_SCRIPT_BNAME=`basename ${BASH_SOURCE}`
#if [ "${AP_SCRIPT_BNAME}" == "bash" ]; then
#    AP_SCRIPT_BNAME="argparse"
#fi

readonly MAX_INDENT=24

######################## main argparse functions ########################
ArgumentParser () {
    # @param parser_name: MUST be the first argument
    # @param --prog: set the name of the program (default: to `basename $0`)
    # @param --usage: description of the program usage (default: generated based on arguments added)
    # @param --description: text to display before the argument help (default: "")
    # @param --epilog=None: text to display after the argument help (default: "")
    # @param --prefix_chars: set of characters that prefix optional arguments (default: "-")
    # @param --fromfile_prefix_chars: set characters that prefix files from which to read additional arguments
    # @param --argument_default: global default value for arguments (default: "")
    # @param --add_help: adds a help argument automatically to the parser (default: "true")

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

    # Parse ArgumentParser args
    local key
    while [ "$#" -gt 0 ]; do
        currarg="$1"
        case "${currarg}" in
            --*)
                currarg=${currarg#--*}
                case "${currarg}" in
                    # Fallthrough is intentional
                    prog|usage|description|epilog|prefix_chars) ;&
                    fromfile_prefix_chars|argument_default|add_help)
                        curr_parser[${currarg}]="$2"
                        shift
                        ;;
                    prog=*|usage=*|description=*|epilog=*|prefix_chars=*) ;&
                    fromfile_prefix_chars=*|argument_default=*|add_help=*)
                        key=${currarg%=*}
                        curr_parser[${key}]=${currarg#*=}
                        ;;
                    *)
                        false; assertReturn "ArgumentParser: unexpected argument: ${currarg%=*}"
                        ;;
                esac
                ;;
            *)
                false; assertReturn "ArgumentParser: unexpected argument: ${currarg%=*}"
                ;;
        esac
        shift
    done

    # Add help arg
    add_argument ${parser_name} "-h" "--help" --action="help"\
        --help="show this help message and exit"
}

add_argument () {
    # @param parser_name: MUST be the first argument; is the value set by ArgumentParser
    # @param name or flags: a name or a list of option strings
    # @param --action: an action string indicating what is to be done when this argument is provided
    # @param --nargs: number of command line args to be consumed
    # @param --const: a constant value required by ceratain actions or nargs
    # @param --default: a default value used if the argument is not provided
    # @param --type: the type to which the command line arg will be converted
    # @param --choices: a discrete comma-separated list of allowed values that the argment may assume
    # @param --required: whether or not an optional argument may be ommitted
    # @param --help: a description of the argument is used for
    # @param --metavar:  a name for the argument in usage messages
    # @param --dest: the name of the variable that will be created for this argument

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
        currarg=$1
        case "${currarg}" in
            --*)
                currarg=${currarg#--*}
                case "${currarg}" in
                    action|nargs|const|default|type|required|help|metavar|dest)
                        if [ -z "${2}" ] || [[ "${2}" == -* ]]; then
                            curr_names+=(--${currarg})
                        else
                            curr_arg[${currarg}]=${2}
                            shift
                        fi
                        ;;
                    # Fallthrough is intentional
                    action=*|nargs=*|const=*|default=*|type=*|required=*) ;&
                    help=*|metavar=*|dest)
                        key=${currarg%=*}
                        curr_arg[${key}]=${currarg#*=}
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
                        curr_names+=(--${currarg}) ;;
                esac
                ;;
            *)
                curr_names+=(${currarg})
                ;;
        esac
        shift
    done

    # Determine type of argument (positional vs. optional) based on names
    [ "${#curr_names[@]}" -gt 0 ]
    assertReturn "add_argument requires at least one name or flag"

    # If number of names is 1 and doesn't start with -, it's positional;
    # otherwise, it's optional
    if [ "${#curr_names[@]}" -eq 1 ] && [[ "${curr_names[0]}" != -* ]]; then
        # Some error checking
        [ -z "${curr_arg[dest]}" ]
        assertReturn "dest supplied twice for positional argument"
        [ -z "${curr_arg[required]}" ]
        assertReturn "'required' is an invalid argument for positionals"

        curr_arg[dest]="${curr_names[0]}"
        unset curr_names[0]
        args_list_name="${curr_parser[posargs]}"
    else
        # Some error checking
        for n in "${curr_names[@]}"; do
            [[ "${n}" == -* ]]
            assertReturn "invalid option string '${n}': must start with a"\
                "character '-'"
        done

        # dest is the first long-opt starting with --
        if [ -z "${curr_arg[dest]}" ]; then
            local dest=${curr_names[0]}
            for n in "${curr_names[@]}"; do
                if [[ "${n}" == --* ]]; then
                    dest="${n}"
                    break
                fi
            done
        fi
        curr_arg[dest]=`echo ${dest} | sed 's/^-*//'`
        args_list_name="${curr_parser[optargs]}"
    fi

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
    opt_strings_name=${arg_var_name}_OPTS
    unset ${opt_strings_name}
    declare -ag ${opt_strings_name}
    eval "${opt_strings_name}=`print_list curr_names`"
    eval "${arg_var_name}[optstrs]=${opt_strings_name}"
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

    local help_str="usage: ${curr_parser[prog]}"

    # Print brief help
    for arg in "${optargs[@]}"; do
        help_str+=" `print_arg_help -b ${arg}`"
    done
    for arg in "${posargs[@]}"; do
        help_str+=" `print_arg_help -b ${arg}`"
    done
    help_str+="\n\n"

    # Determine indentation
    local indent=0
    local tmp_str
    local margin=80
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

    # Perform string substitution
    help_str="${help_str//%(prog)/${curr_parser[prog]}}"

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
    local margin=80
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

print_list () {
    # Prints a map (associative array) such that it can be used to initialize
    # another array with the same output
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

is_valid_name () {
    local name_under_test="$1"
    [[ "${name_under_test}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}

