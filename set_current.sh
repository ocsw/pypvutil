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

pyact () {
    local venv="$1"
    if [ -n "$venv" ]; then
        pyenv activate "$venv"
    else
        pyenv deactivate || return "$?"
        if [ "$(pyenv global)" != "$(pycur)" ]; then
            cat <<EOF
WARNING: Global env was set but isn't active; are you in a directory with a
.python-version file?
EOF
            return 1
        fi
    fi
}

_pyact_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_venv_complete
    fi
}
complete -o default -F _pyact_complete pyact

# wrap 'pyenv global' for convenience, preserving autocomplete
pyglobal () {
    local env="$1"  # base or venv
    pyenv global "$env"  # if empty, just prints current
}

_pyglobal_complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    if [ "$COMP_CWORD" = "1" ]; then
        COMPREPLY=()
        if [[ "system" =~ ^$cur_word ]] || [[ "-f" =~ ^$cur_word ]]; then
            COMPREPLY=("system")
        fi
        _py_all_complete all
    fi
}
complete -o default -F _pyglobal_complete pyglobal
