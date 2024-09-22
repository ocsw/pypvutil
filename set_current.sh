#!/usr/bin/env bash

# Copyright 2018-2019 Danielle Zephyr Malament
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#####################
# set current state #
#####################

pypvutil_act () {
    local venv="$1"
    if [ -n "$venv" ]; then
        pyenv activate "$venv"
    else
        pyenv deactivate || return "$?"
        if [ "$(pyenv global)" != "$(pypvutil_cur)" ]; then
            cat <<EOF
WARNING: Global env was set but isn't active; are you in a directory with a
.python-version file?
EOF
            return 1
        fi
    fi
}

_pypvutil_act_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_venv_completions
    fi
}
complete -o default -F _pypvutil_act_complete pypvutil_act
_pypvutil_create_alias "act" "yes"


# wrap 'pyenv global' for convenience, preserving autocomplete
pypvutil_global () {
    local env="$1"  # base or venv
    pyenv global "$env"  # if empty, just prints current
}

_pypvutil_global_complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    if [ "$COMP_CWORD" = "1" ]; then
        COMPREPLY=()
        if [[ system =~ ^$cur_word ]]; then
            COMPREPLY+=("system")
        fi
        _pypvutil_all_completions add
    fi
}
complete -o default -F _pypvutil_global_complete pypvutil_global
_pypvutil_create_alias "global" "yes"


# wrap 'pyenv local' for convenience, preserving autocomplete
pypvutil_local () {
    local env="$1"  # base or venv
    pyenv local "$env"  # if empty, just prints current
}

_pypvutil_local_complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    if [ "$COMP_CWORD" = "1" ]; then
        COMPREPLY=()
        if [[ system =~ ^$cur_word ]]; then
            COMPREPLY+=("system")
        fi
        if [[ --unset =~ ^$cur_word ]]; then
            COMPREPLY+=("--unset")
        fi
        _pypvutil_all_completions add
    fi
}
complete -o default -F _pypvutil_local_complete pypvutil_local
_pypvutil_create_alias "local" "yes"


_pypvutil_ide_vscode_usage () {
    cmd_name=$(_pypvutil_get_cmd_name "ide_vscode")
    cat 1>&2 <<EOF
Usage:
    $cmd_name -s|--set PYTHON_ENV [OPTIONS]
    $cmd_name -u|--unset [OPTIONS]
    $cmd_name -g|--get [OPTIONS]

Sets, unsets, or gets the VSCode 'python.defaultInterpreterPath' workspace
setting.

When setting the value, PYTHON_ENV can be a virtualenv, an installed base
version, or '2' or '3'.  With '2' or '3', the latest installed Python release
with that major version will be used.

The command must be run from the root of the VSCode project directory.
Alternatively, specify '-f|--file PATH_TO_SETTINGS_FILE'; this is particularly
useful for multi-folder workspace files.  Additionally, for multi-folder
workspace files use '-w|--workspace', which puts the settings under the
'settings' section of the file (rather than at the top level, as in regular
config files).

The file will be formatted with 4-space indents when setting or unsetting the
value; to change this, specify '-i|--indent NUM'.

Options can appear in any order.  Later options override earlier ones.
EOF
}

# uses the vscode-setting function, which uses jq
pypvutil_ide_vscode () {
    local mode=""
    local py_env=""
    local vsc_settings_file=".vscode/settings.json"
    local workspace_arg=""
    local indent=4
    local new_python_path

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -s|--set)
                mode="set"
                py_env="$2"
                shift
                shift
                ;;
            -u|--unset)
                mode="unset"
                shift
                ;;
            -g|--get)
                mode="get"
                shift
                ;;
            -f|--file)
                vsc_settings_file="$2"
                shift
                shift
                ;;
            -w|--workspace)
                workspace_arg="-w"
                shift
                ;;
            -i|--indent)
                indent="$2"
                shift
                shift
                ;;
            -h|--help)
                _pypvutil_ide_vscode_usage
                return 0
                ;;
            *)
                _pypvutil_ide_vscode_usage
                return 1
                ;;
        esac
    done

    if [ -z "$mode" ]; then
        _pypvutil_ide_vscode_usage
        echo 1>&2
        echo "ERROR: No action (set/unset/get) specified." 1>&2
        return 1
    fi

    if [ "$mode" = "set" ] && [ -z "$py_env" ]; then
        _pypvutil_ide_vscode_usage
        echo 1>&2
        echo "ERROR: No Python environment specified." 1>&2
        return 1
    fi

    if [ "$py_env" = "2" ] || [ "$py_env" = "3" ]; then
        if ! py_env=$(pypvutil_latest "$py_env" "installed_only"); then
            # pypvutil_latest will have emitted an error message
            return 1
        fi
    fi

    if [ "$mode" = "get" ]; then
        vscode-setting -f "$vsc_settings_file" $workspace_arg -i "$indent" \
            -g "python.defaultInterpreterPath"
    elif [ "$mode" = "unset" ]; then
        vscode-setting -f "$vsc_settings_file" $workspace_arg -i "$indent" \
            -u "python.defaultInterpreterPath"
    elif [ "$mode" = "set" ]; then
        if ! new_python_path="$(pypvutil_bin_dir "$py_env")/python"; then
            # pypvutil_bin_dir will have emitted an error message
            return 1
        fi
        vscode-setting -f "$vsc_settings_file" $workspace_arg -i "$indent" \
            -s "python.defaultInterpreterPath" "$new_python_path"
    fi
}

_pypvutil_ide_vscode_complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    local prev_word=""

    if [ "$COMP_CWORD" -ge 1 ]; then
        prev_word="${COMP_WORDS[$COMP_CWORD-1]}"
    fi

    if [ "$prev_word" = "-s" ] || [ "$prev_word" = "--set" ]; then
        COMPREPLY=()
        _pypvutil_all_completions add
        _pypvutil_latest_completions add
        return 0
    fi
    if [ "$prev_word" = "-f" ] || [ "$prev_word" = "--file" ]; then
        COMPREPLY=()
        return 0
    fi
    if [ "$prev_word" = "-i" ] || [ "$prev_word" = "--indent" ]; then
        # jq only allows 0-7
        COMPREPLY=(0 1 2 3 4 5 6 7)
        return 0
    fi

    if [[ -z $cur_word ]] || [[ $cur_word = - ]]; then
        COMPREPLY=(
            -s --set -u --unset -g --get -f --file -w --workspace -i --indent
            -h --help
        )
        return 0
    fi
    if [[ $cur_word = -- ]]; then
        COMPREPLY=(--set --unset --get --file --workspace --indent --help)
        return 0
    fi

    if [[ "-s" =~ ^$cur_word ]]; then
        COMPREPLY+=("-s")
    elif [[ --set =~ ^$cur_word ]]; then
        COMPREPLY+=("--set")
    #
    elif [[ "-u" =~ ^$cur_word ]]; then
        COMPREPLY+=("-u")
    elif [[ --unset =~ ^$cur_word ]]; then
        COMPREPLY+=("--unset")
    #
    elif [[ "-g" =~ ^$cur_word ]]; then
        COMPREPLY+=("-g")
    elif [[ --get =~ ^$cur_word ]]; then
        COMPREPLY+=("--get")
    #
    elif [[ "-f" =~ ^$cur_word ]]; then
        COMPREPLY+=("-f")
    elif [[ --file =~ ^$cur_word ]]; then
        COMPREPLY+=("--file")
    #
    elif [[ "-w" =~ ^$cur_word ]]; then
        COMPREPLY+=("-w")
    elif [[ --workspace =~ ^$cur_word ]]; then
        COMPREPLY+=("--workspace")
    #
    elif [[ "-i" =~ ^$cur_word ]]; then
        COMPREPLY+=("-i")
    elif [[ --indent =~ ^$cur_word ]]; then
        COMPREPLY+=("--indent")
    #
    elif [[ "-h" =~ ^$cur_word ]]; then
        COMPREPLY+=("-h")
    elif [[ --help =~ ^$cur_word ]]; then
        COMPREPLY+=("--help")
    fi
}
complete -o default -F _pypvutil_ide_vscode_complete pypvutil_ide_vscode
_pypvutil_create_alias "ide_vscode" "yes"
