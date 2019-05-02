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

##########
# delete #
##########

# wrap 'pyenv uninstall' for convenience, preserving autocomplete
pypvutil_rm () {
    pyenv uninstall "$@"
}

_pypvutil_rm_complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    if [ "$COMP_CWORD" = "1" ] || [ "$COMP_CWORD" = "2" ]; then
        COMPREPLY=()
        if [[ "--force" =~ ^$cur_word ]] || [[ "-f" =~ ^$cur_word ]]; then
            COMPREPLY+=("--force")
        fi
        _pypvutil_all_completions add
    fi
}
complete -o default -F _pypvutil_rm_complete pypvutil_rm
_pypvutil_create_alias "rm" "yes"
