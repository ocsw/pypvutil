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

###################
# update / change #
###################

pypvutil_reqs () {
    # install a project's requirements in a pyenv-virtualenv virtualenv
    pypvutil_wrapper _pypvutil_reqs "$@"
}

_pypvutil_reqs () {
    local cmd_name
    local venv="$1"
    local project_dir="$2"
    local i

    if [ -z "$venv" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "reqs")
        echo "Usage: $cmd_name VIRTUALENV PROJECT_DIRECTORY"
        echo
        echo "ERROR: No virtualenv given."
        return 1
    fi
    if [ -z "$project_dir" ]; then
        echo "ERROR: No project directory given."
        return 1
    fi
    if [ ! -d "$project_dir" ]; then
        echo "ERROR: Bad project directory."
        return 1
    fi
    if ! compgen -G "$project_dir/*requirements.txt" \
            > /dev/null 2>&1; then
        echo "ERROR: No requirements files in project directory."
        return 1
    fi

    if ! pyenv activate "$venv"; then
        echo
        echo "ERROR: Can't activate virtualenv.  Stopping."
        echo
        return 1
    fi
    if ! cd "$project_dir"; then
        echo
        echo "ERROR: Can't change to project directory.  Stopping."
        echo
        return 1
    fi
    for i in *requirements.txt; do
        pip install -r "$i"
    done

    return 0
}

_pypvutil_reqs_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_venv_completions
    fi
}
complete -o default -F _pypvutil_reqs_complete pypvutil_reqs
_pypvutil_create_alias "reqs" "yes"


pypvutil_pipcopy () {
    # add the packages from one virtualenv to another virtualenv
    pypvutil_wrapper _pypvutil_pipcopy "$@"
}

_pypvutil_pipcopy () {
    local cmd_name
    local source_venv="$1"
    local target_venv="$2"
    local reqs_file
    if [ -z "$source_venv" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "pipcopy")
        echo "Usage: $cmd_name SOURCE_VIRTUALENV TARGET_VIRTUALENV"
        echo
        echo "ERROR: No source virtualenv given."
        return 1
    fi
    if ! pyname_is_venv "$source_venv"; then
        echo "ERROR: Source virtualenv not found."
        return 1
    fi
    if [ -z "$target_venv" ]; then
        echo "ERROR: No target virtualenv given."
        return 1
    fi
    if ! pyname_is_venv "$target_venv"; then
        echo "ERROR: Target virtualenv not found."
        return 1
    fi
    if [ "$source_venv" = "$target_venv" ]; then
        echo "ERROR: Source and target are the same."
        return 1
    fi

    if ! pyenv activate "$source_venv"; then
        echo
        echo "ERROR: Can't activate source virtualenv.  Stopping."
        echo
        return 1
    fi
    reqs_file=$(mktemp)
    if [ -z "$reqs_file" ]; then
        echo
        echo "ERROR: Can't create temp file.  Stopping."
        echo
        return 1
    fi
    if ! pip freeze --all --local >| "$reqs_file"; then
        echo
        echo "ERROR: Can't get package list.  Stopping."
        echo
        return 1
    fi
    if ! pyenv activate "$target_venv"; then
        echo
        echo "ERROR: Can't activate target virtualenv.  Stopping."
        echo
        return 1
    fi
    if ! pip install -r "$reqs_file"; then
        echo
        echo "ERROR: Can't install packages.  Stopping."
        echo
        rm -rf "$reqs_file"
        return 1
    fi
    rm -rf "$reqs_file"
}

_pypvutil_pipcopy_complete () {
    if [ "$COMP_CWORD" = "1" ] || [ "$COMP_CWORD" = "2" ]; then
        _pypvutil_venv_completions
    fi
}
complete -o default -F _pypvutil_pipcopy_complete pypvutil_pipcopy
_pypvutil_create_alias "pipcopy" "yes"
