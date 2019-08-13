#!/bin/bash
#argparse.sh

assertReturn () {
    local retval=$?
    local errmsg=$1
    if [ "${retval}" != "0" ]; then
        echo "ERROR: ${errmsg}"
        exit 1
    fi
}

# Get script name
AP_SCRIPT_BNAME=`basename ${BASH_SOURCE}`
if [ "${AP_SCRIPT_BNAME}" == "bash" ]; then
    AP_SCRIPT_BNAME="argparse"
fi

# Get mode
ap_mode="$1"
shift
[ ! -z "${ap_mode}" ]
assertReturn "must provide ${AP_SCRIPT_BNAME} mode"

ArgumentParserFunc () {
    # @param --prog: set the name of the program
    # @param --usage: description

    # Clear previous variables
    unset AP_OBJ

    # Parse ArgumentParser args
    while [ "$#" -gt 0 ]; do
        currarg=$1
        echo "currarg=${currarg}"
        case "${currarg}" in
            --prog)
                AP_OBJ[prog]="$2"; shift ;;
            --prog=*)
                AP_OBJ[prog]=${currarg#*=} ;;
            *) ;;
        esac
        shift
    done

    # Add help arg
    . ${BASH_SOURCE} add_argument "-h" "--help" --action="help" --help="show this help message and exit"
}

add_argumentFunc () {
    # @param name or flags: a name or a list of option strings
    # @param --action: an action string indicating what is to be done when this
    #   argument is provided
    # @param --nargs: number of command line args to be consumed
    # @param --const: a constant value required by ceratain actions or nargs
    # @param --default: a default value used if the argument is not provided
    # @param --type: the type to which the command line arg will be converted
    # @param --choices: a discrete comma-separated list of allowed values that
    #   the argment may assume
    # @param --required: whether or not an optional argument may be ommitted
    # @param --help: a description of the argument is used for
    # @param --metavar:  a name for the argument in usage messages
    # @param --dest: the name of the variable that will be created for this
    #   argument

    # Create local variables
    unset temp_arg
    declare -A temp_arg=([action]="store")
    local key
    local prev_arg
    local temp_names=()

    # Parse all inputs
    while [ $# -gt 0 ]; do
        unset OPTIND OPTARG
        # TODO: do we really need getopts?
        while getopts ":-:" opt; do
            case "${opt}" in
                -)
                    case "${OPTARG}" in
                        action|nargs|const|default|type|required|help|metavar|dest)
                            if [ -z "${!OPTIND}" ] || [[ "${!OPTIND}" == -* ]]; then
                                temp_names+=(--${OPTARG})
                            else
                                temp_arg[${OPTARG}]=${!OPTIND}
                                ((OPTIND++))
                            fi
                            ;;
                        action=*|nargs=*|const=*|default=*|type=*|required=*|help=*|metavar=*|dest)
                            key=${OPTARG%=*}
                            temp_arg[${key}]=${OPTARG#*=}
                            ;;
                        choices)
                            unset temp_choices
                            IFS="," read -ra temp_choices <<< "${!OPTIND}"
                            ((OPTIND++))
                            ;;
                        choices=*)
                            unset temp_choices
                            IFS="," read -ra temp_choices <<< "${opt#*=}"
                            ;;
                        *) 
                            temp_names+=(--${OPTARG}) ;;
                    esac
                    ;;
                *)
                    prev_ind=$((OPTIND-1))
                    temp_names+=(${!prev_ind})
                    ;;
            esac
        done
        shift $((OPTIND-1))
        temp_names+=($1)
        shift
    done
    echo "DEBUG `print_list temp_names`"
    echo "DEBUG `print_map temp_arg`"

    # Determine type of argument (positional vs. optional) based on names
    [ "${#temp_names[@]}" -gt 0 ]
    assertReturn "add_argument requires at least one name or flag"

    # If number of names is 1 and doesn't start with -, it's positional;
    # otherwise, it's optional
    if [ "${#temp_names[@]}" -eq 1 ] && [[ "${temp_names[0]}" != -* ]]; then
        # Some error checking
        [ -z "${temp_arg[dest]}" ]
        assertReturn "dest supplied twice for positional argument"
        [ -z "${temp_arg[required]}" ]
        assertReturn "'required' is an invalid argument for positionals"

        temp_arg[dest]="${temp_names[0]}"
    else
        # Some error checking
        for n in "${temp_names[@]}"; do
            [[ "${n}" == -* ]]
            assertReturn "invalid option string '${n}': must start with a character '-'"
        done

        # TODO: dest name is the first long-opt starting with --
        if [ -z "${temp_arg[dest]}" ]; then
            local dest=${temp_names[0]}
            for n in "${temp_names[@]}"; do
            done
        fi
    fi

        


    # Create a global object

}

print_helpFunc () {
    echo "inside print_help"
}

print_map () {
    mapname=$1
    declare -n currmap=${mapname}
    print_str="${mapname}=("
    for k in "${!currmap[@]}"; do
        print_str+="[${k}]=${currmap[${k}]} "
    done
    print_str+=")"
    echo "${print_str}"
}

print_list () {
    listname=$1
    declare -n currlist=${listname}
    print_str="${listname}=("
    for v in "${currlist[@]}"; do
        print_str+="\"${v}\" "
    done
    print_str+=")"
    echo "${print_str}"
}

case ${ap_mode} in
    ArgumentParser) ArgumentParserFunc "$@" ;;
    add_argument) add_argumentFunc "$@" ;;
    print_help) print_helpFunc "$@" ;;
    *) false; assertReturn "unknown ${AP_SCRIPT_BNAME} mode: ${ap_mode}"; ;;
esac

echo `print_map AP_OBJ`

