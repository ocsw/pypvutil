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
# get current state #
#####################

pypvutil_cur () {
    printf "%s\n" "$(pyenv version | sed 's/ (.*$//')"
}
_pypvutil_create_alias "cur" "no"

pypvutil_cur_is_global () {
    [ -z "$PYENV_VERSION" ] && [ -z "$PYENV_VIRTUAL_ENV" ]
}
_pypvutil_create_alias "cur_is_global" "no"

pypvutil_cur_is_venv () {
    [ -n "$PYENV_VERSION" ] && [ -n "$PYENV_VIRTUAL_ENV" ]
}
_pypvutil_create_alias "cur_is_venv" "no"

pypvutil_cur_is_dotfile () {
    [ -z "$PYENV_VERSION" ] && [ -n "$PYENV_VIRTUAL_ENV" ]
}
_pypvutil_create_alias "cur_is_dotfile" "no"


pypvutil_bases_available () {
    pyenv install --list | tail -n +2 | sed 's/^..//'
}
_pypvutil_create_alias "bases_available" "no"

pypvutil_bases_installed () {
    # see:
    # https://unix.stackexchange.com/questions/275637/limit-posix-find-to-specific-depth
    find "${PYENV_ROOT}/versions/." ! -name . -prune -type d |
        sed "s|^${PYENV_ROOT}/versions/\./||"
}
_pypvutil_create_alias "bases_installed" "no"


pypvutil_venvs () {
    pyenv virtualenvs | sed -e 's/^..//' -e 's/ (.*$//' |
        grep -v "/envs/"
}
_pypvutil_create_alias "venvs" "no"


pypvutil_name_is_global () {
    local cmd_name
    local name="$1"
    if [ -z "$name" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "name_is_global")
        printf "%s\n" "Usage: $cmd_name NAME"
        echo
        echo "ERROR: No name given."
        return 1
    fi
    pypvutil_bases_installed | grep "^${name}\$" > /dev/null 2>&1
}
_pypvutil_create_alias "name_is_global" "no"

pypvutil_name_is_venv () {
    local cmd_name
    local name="$1"
    if [ -z "$name" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "name_is_venv")
        printf "%s\n" "Usage: $cmd_name NAME"
        echo
        echo "ERROR: No name given."
        return 1
    fi
    pypvutil_venvs | grep "^${name}\$" > /dev/null 2>&1
}
_pypvutil_create_alias "name_is_venv" "no"


pypvutil_latest () {
    # get the latest available (or latest locally installed) version of
    # Python for a specified major version in pyenv
    local cmd_name
    local major_version="$1"
    local installed_only="$2"
    local versions ver

    if [ -n "$major_version" ] && [ "$major_version" != "2" ] &&
            [ "$major_version" != "3" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "latest")
        cat <<EOF
Usage: $cmd_name [MAJOR_PY_VERSION] [INSTALLED_ONLY]
MAJOR_PY_VERSION defaults to 3.
If INSTALLED_ONLY is given, only installed pyenv base versions will be
examined.

ERROR: If given, MAJOR_PY_VERSION must be 2 or 3.
EOF
        return 1
    fi
    [ -z "$major_version" ] && major_version="3"

    # see:
    # https://stackoverflow.com/questions/742466/how-can-i-reverse-the-order-of-lines-in-a-file
    # https://web.archive.org/web/20090227054719/http://student.northpark.edu/pemente/awk/awk1line.txt
    versions=$(pyenv install --list | tail -n +2 | sed 's/^..//' |
        grep "^${major_version}\.[0-9]" | grep -vi "[a-z]" |
        awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--]}')

    if [ -z "$installed_only" ]; then
        printf "%s\n" "$versions" | head -n 1
        return 0
    fi
    for ver in $versions; do
        if [ -d "${PYENV_ROOT}/versions/$ver" ]; then
            printf "%s\n" "$ver"
            return 0
        fi
    done

    echo "ERROR: No Python environment found for specified major version." 1>&2
    return 1
}

pypvutil_latest_local () { pypvutil_latest "$1" "installed_only"; }

_pypvutil_create_alias "latest" "no"
_pypvutil_create_alias "latest_local" "no"


pypvutil_venv_version () {
    # get the version of a virtualenv; don't rely on the name
    local cmd_name
    local venv="$1"
    local py_version
    if [ -z "$venv" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "venv_version")
        printf "%s\n" "Usage: $cmd_name VIRTUALENV"
        echo
        echo "ERROR: No virtualenv given."
        return 1
    fi
    if ! pyname_is_venv "$venv"; then
        echo "ERROR: Virtualenv not found."
        return 1
    fi

    py_version=$(pyenv versions | sed -e 's/^..//' -e 's/ (.*$//' |
        grep "/envs/${venv}\$" | grep -v ' --> ' | sed 's|/.*$||')
    if [ -z "$py_version" ]; then
        echo
        echo "ERROR: Can't get version for virtualenv."
        echo
        return 1
    fi
    printf "%s\n" "$py_version"
}

_pypvutil_venv_version_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_venv_completions
    fi
}
complete -o default -F _pypvutil_venv_version_complete pypvutil_venv_version
_pypvutil_create_alias "venv_version" "yes"
