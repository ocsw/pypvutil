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
        _pypvutil_all_completions all
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
        _pypvutil_all_completions all
    fi
}
complete -o default -F _pypvutil_local_complete pypvutil_local
_pypvutil_create_alias "local" "yes"


# add 'python.pythonPath' setting to VSCode in a directory; uses jq
pypvutil_ide_vscode () {
    local cmd_name
    local py_env="$1"
    local vsc_dir=".vscode"
    local vsc_settings_file="${vsc_dir}/settings.json"
    local cur_setting
    local new_file_contents
    local new_python_path

    if ! hash jq > /dev/null 2>&1; then
        echo "ERROR: The jq utility isn't available."
        return 1
    fi

    if [ -z "$py_env" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "ide_vscode")
        cat <<EOF
Usage: $cmd_name PYTHON_ENV | --unset | --get

Sets, unsets, or gets the 'python.pythonPath' setting for VSCode.

PYTHON_ENV can be a virtualenv, an installed base version, or '2' or '3'.  With
'2' or '3', the latest installed Python release with that major version will be
used.

Must be run from the root of the VSCode project directory.

ERROR: No Python environment given.
EOF
        return 1
    fi

    if [ "$py_env" = "2" ] || [ "$py_env" = "3" ]; then
        py_env=$(pypvutil_latest "$py_env" "installed_only")
    fi

    if [ "$py_env" = "--get" ]; then
        if ! [ -f "$vsc_settings_file" ]; then
            return 0
        fi
        if ! cur_setting=$(jq '."python.pythonPath"' < "$vsc_settings_file" \
                2>/dev/null); then
            echo "ERROR: Can't process VSCode settings file."
            return 1
        fi
        # remove JSON quotes
        cur_setting="${cur_setting#\"}"
        cur_setting="${cur_setting%\"}"
        if [ -z "$cur_setting" ] || [ "$cur_setting" = "null" ]; then
            return 0
        fi
        printf "%s\n" "$cur_setting"
    elif [ "$py_env" = "--unset" ]; then
        if ! [ -f "$vsc_settings_file" ]; then
            return 0
        fi
        if ! new_file_contents=$(jq --indent 4 'del(."python.pythonPath")' \
                < "$vsc_settings_file"); then
            echo "ERROR: Can't process VSCode settings file."
            return 1
        fi
        # this isn't ideal, but it's portable, unlike something like mktemp,
        # and it should be fine in this context; Bash variables can contain
        # many megabytes, and the command-line-length limit doesn't apply to
        # builtins like printf
        # see:
        # https://stackoverflow.com/questions/5076283/shell-variable-capacity
        # https://stackoverflow.com/questions/19354870/bash-command-line-and-input-limit
        printf "%s\n" "$new_file_contents" >| "$vsc_settings_file"
    else  # set
        if ! new_python_path="$(pypvutil_bin_dir "$py_env")/python"; then
            # pypvutil_bin_dir will have emitted an error message
            return 1
        fi
        mkdir -p "$vsc_dir"
        # the jq addition won't work on a blank file
        if ! [ -f "$vsc_settings_file" ] || \
                ! grep '{' "$vsc_settings_file" > /dev/null 2>&1; then
            echo "{}" >| "$vsc_settings_file"
        fi
        if ! new_file_contents=$(jq --indent 4 \
                --arg pythonPath "$new_python_path" \
                '. + {"python.pythonPath": $pythonPath}' \
                < "$vsc_settings_file"); then
            echo "ERROR: Can't process VSCode settings file."
            return 1
        fi
        # see note above, in the --unset section
        printf "%s\n" "$new_file_contents" >| "$vsc_settings_file"
    fi
}

_pypvutil_ide_vscode_complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    if [ "$COMP_CWORD" = "1" ]; then
        COMPREPLY=()
        if [[ --get =~ ^$cur_word ]]; then
            COMPREPLY+=("--get")
        fi
        if [[ --unset =~ ^$cur_word ]]; then
            COMPREPLY+=("--unset")
        fi
        _pypvutil_all_completions add
    fi
}
complete -o default -F _pypvutil_ide_vscode_complete pypvutil_ide_vscode
_pypvutil_create_alias "ide_vscode" "yes"
