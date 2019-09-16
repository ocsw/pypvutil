#!/usr/bin/env bash

# Copyright 2018 Danielle Zephyr Malament
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
        # quotes needed because -f is an operator
        if [[ system =~ ^$cur_word ]] || [[ "-f" =~ ^$cur_word ]]; then
            COMPREPLY=("system")
        fi
        _pypvutil_all_completions all
    fi
}
complete -o default -F _pypvutil_global_complete pypvutil_global
_pypvutil_create_alias "global" "yes"
