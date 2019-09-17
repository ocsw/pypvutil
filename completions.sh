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

###############
# completions #
###############

_pypvutil_base_completions () {
    local ver_func="$1"
    local add="$2"
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    if [ -z "$add" ]; then
        # seems to not be necessary, but just in case...
        COMPREPLY=()
    fi
    while read -r line; do
        COMPREPLY+=("$line")
    done < <("$ver_func" | grep "^${cur_word}")
    [ -n "$line" ] && COMPREPLY+=("$line")
}

_pypvutil_latest_completions () {
    local add="$1"
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    if [ -z "$add" ]; then
        # seems to not be necessary, but just in case...
        COMPREPLY=()
    fi
    if [ -z "$cur_word" ]; then
        COMPREPLY+=(2 3)
    elif [ "$cur_word" = "2" ]; then
        COMPREPLY+=(2)
    elif [ "$cur_word" = "3" ]; then
        COMPREPLY+=(3)
    fi
}

_pypvutil_venv_completions () {
    local add="$1"
    if [ -z "$add" ]; then
        # seems to not be necessary, but just in case...
        COMPREPLY=()
    fi
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    while read -r line; do
        COMPREPLY+=("$line")
    done < <(pypvutil_venvs | grep "^${cur_word}")
    [ -n "$line" ] && COMPREPLY+=("$line")
}

_pypvutil_all_completions () {
    local add="$1"
    if [ -z "$add" ]; then
        # seems to not be necessary, but just in case...
        COMPREPLY=()
    fi
    # bases first, for pypvutil_global
    _pypvutil_base_completions pypvutil_bases_installed add
    _pypvutil_venv_completions add
}
