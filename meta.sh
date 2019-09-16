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

_python_venv_prompt () {
    # Note: 'pyenv activate' uses $PYENV_VERSION, which pyenv checks first.
    # In order for a .python_version to take effect (which uses
    # $PYENV_VIRTUAL_ENV), you must be on the global pyenv version (i.e. do
    # 'pyenv deactivate').
    # ('pyenv activate' actually also sets $PYENV_VIRTUAL_ENV, but what matters
    # for us here is $PYENV_VERSION.)
    if [ -n "$PYENV_VERSION" ]; then
        printf "%s " "$PYENV_VERSION"
    elif [ -n "$PYENV_VIRTUAL_ENV" ]; then
        printf "%s " "${PYENV_VIRTUAL_ENV##*/}"
    fi
}

# check for availability of a command (or commands);
# searches both the PATH and functions
# see also https://github.com/koalaman/shellcheck/wiki/SC2230
is_available () {
    hash "$@" > /dev/null 2>&1
}

if is_available pip ||
        is_available pip2 ||
        is_available pip3; then
    _pip_completion () {
        # shellcheck disable=SC2207
        COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                       COMP_CWORD=$COMP_CWORD \
                       PIP_AUTO_COMPLETE=1 $1 ) )
    }
    is_available pip && complete -o default -F _pip_completion pip
    is_available pip2 && complete -o default -F _pip_completion pip2
    is_available pip3 && complete -o default -F _pip_completion pip3
fi

if is_available pyenv; then
    eval "$(pyenv init - | grep -v "PATH")"
fi
if is_available pyenv-virtualenv-init; then
    eval "$(pyenv virtualenv-init - | grep -v "PATH")"
fi
