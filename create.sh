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

####################
# install / create #
####################

pypvutil_base () {
    # install a version of Python in pyenv
    local cmd_name
    local cflags_add="-O2"
    local py_version="$1"

    if [ -z "$py_version" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "base")
        cat <<EOF
Usage: $cmd_name PY_VERSION [PYENV_INSTALL_ARGS]
If PY_VERSION is 2 or 3, the latest available Python release with that major
version will be used.

ERROR: No Python version given.
EOF
        return 1
    fi
    if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
        if ! py_version=$(pypvutil_latest "$py_version"); then
            # pypvutil_latest will have emitted an error message
            return 1
        fi
    fi
    shift

    CFLAGS="$cflags_add $CFLAGS" pyenv install "$@" "$py_version"
}

_pypvutil_base_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_base_completions pypvutil_bases_available
        _pypvutil_latest_completions add
    fi
}
complete -o default -F _pypvutil_base_complete pypvutil_base
_pypvutil_create_alias "base" "yes"


pypvutil_wrapper () {
    # clean up after the Python helpers, below
    local cmd_name
    local wrapped="$1"
    local prev_wd="$PWD"
    local prev_venv
    local global_env
    local retval

    if [ -z "$wrapped" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "wrapper")
        echo "Usage: $cmd_name COMMAND [ARGS]"
        echo
        echo "ERROR: No command given."
        return 1
    fi

    shift

    prev_venv=$(pypvutil_cur)

    "$wrapped" "$@"
    retval="$?"

    cd "$prev_wd" || true  # ignore failure
    if [ "$(pypvutil_cur)" != "$prev_venv" ]; then
        global_env=$(pyenv global)
        if [ "$prev_venv" != "$global_env" ]; then
            pyenv activate "$prev_venv"
        else
            pyenv deactivate
        fi
    fi

    return "$retval"
}

_pypvutil_create_alias "wrapper" "no"


pypvutil_fix () {
    # fix a couple of things in a virtualenv that don't seem to come out
    # right by default
    pypvutil_wrapper _pypvutil_fix "$@"
}

_pypvutil_fix () {
    local cmd_name
    local venv="$1"
    local py_version
    local major
    local major_minor

    if [ -z "$venv" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "fix")
        echo "Usage: $cmd_name VIRTUALENV"
        echo
        echo "ERROR: No virtualenv given."
        return 1
    fi
    if ! pypvutil_venvs | grep "^$venv\$" > /dev/null 2>&1; then
        echo "ERROR: \"$venv\" is not a valid virtualenv."
        return 1
    fi

    # tox seems to look directly in virtualenvs' bin directories, and
    # requires a minor-versioned python binary (e.g. python3.6), which the
    # above doesn't seem to provide (at least for python3).
    py_version=$(grep "^version *= *" \
        "${PYENV_ROOT}/versions/${venv}/pyvenv.cfg" | \
        sed 's/^version *= *//')
    major=$(printf "%s\n" "$py_version" | \
        sed 's/^\([0-9]\)\.[0-9]\.[0-9]$/\1/')
    major_minor=$(printf "%s\n" "$py_version" | \
        sed 's/^\([0-9]\.[0-9]\)\.[0-9]$/\1/')
    if ! cd "${PYENV_ROOT}/versions/${venv}/bin"; then
        cat << EOF

ERROR: Can't change to bin directory.  Stopping.
Target: ${PYENV_ROOT}/versions/${venv}/bin

EOF
        return 1
    fi
    ln -s "python$major" "python$major_minor"

    # I haven't figured out how to make new virtualenvs have new pip;
    # pyenv global 3.6.5; pyenv deactivate; pip install --upgrade pip
    # will update the base image, but that apparently won't affect the new
    # ones.  I thought the problem might be with ensurepip, but that
    # doesn't seem to be it either.
    pyenv activate "$venv"
    pip install --upgrade pip
}

_pypvutil_fix_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_venv_completions
    fi
}
complete -o default -F _pypvutil_fix_complete pypvutil_fix
_pypvutil_create_alias "fix" "yes"

pypvutil_fix_all () {
    local venv
    for venv in $(pypvutil_venvs); do
        echo "Fixing virtualenv \"$venv\"..."
        pypvutil_fix "$venv"
    done
    echo "Done."
}

_pypvutil_create_alias "fix_all" "no"


pypvutil_venv () {
    # create a pyenv-virtualenv virtualenv with a bunch of tweaks and
    # installs
    pypvutil_wrapper _pypvutil_venv "$@"
}

_pypvutil_venv () {
    local cmd_name
    local short_name="$1"
    local py_version="$2"
    local project_dir="$3"
    local full_name

    if [ -z "$short_name" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "venv")
        cat <<EOF
Usage: $cmd_name SHORT_NAME PY_VERSION [PROJECT_DIRECTORY]
If PY_VERSION is 2 or 3, the latest installed Python release with that major
version will be used.

ERROR: No short name given.
EOF
        return 1
    fi
    if [ -z "$py_version" ]; then
        echo "ERROR: No Python version given."
        return 1
    fi
    if [ -n "$project_dir" ] && ! [ -d "$project_dir" ]; then
        echo "ERROR: Bad project directory."
        return 1
    fi
    if [ -n "$project_dir" ] && \
            ! compgen -G "$project_dir/*requirements*.txt" \
            > /dev/null 2>&1; then
        cat <<EOF
ERROR: No requirements files in project directory; try again without it.
EOF
        return 1
    fi

    if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
        if ! py_version=$(pypvutil_latest "$py_version" "installed_only"); then
            # pypvutil_latest will have emitted an error message
            return 1
        fi
    fi
    full_name="${short_name}-${py_version}"

    if ! pyenv virtualenv "$py_version" "$full_name"; then
        echo
        echo "ERROR: Can't create virtualenv.  Stopping."
        echo
        return 1
    fi
    pypvutil_fix "$full_name"
    if [ -n "$project_dir" ]; then
        pypvutil_reqs "$full_name" "$project_dir"
    fi
    cat <<EOF

New Python path:
${PYENV_ROOT}/versions/${full_name}/bin/python

EOF

    return 0
}

_pypvutil_venv_complete () {
    if [ "$COMP_CWORD" = "2" ]; then
        _pypvutil_base_completions pypvutil_bases_installed
        _pypvutil_latest_completions add
    fi
}
complete -o default -F _pypvutil_venv_complete pypvutil_venv
_pypvutil_create_alias "venv" "yes"


pypvutil_bin_dir () {
    local cmd_name
    local py_env="$1"
    if [ -z "$py_env" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "bin_dir")
        cat <<EOF
Usage: $cmd_name PYTHON_ENV

PYTHON_ENV can be a virtualenv or an installed base version.

ERROR: No Python environment given.
EOF
        return 1
    fi
    if ! pypvutil_name_is_global "$py_env" && \
            ! pypvutil_name_is_venv "$py_env"; then
        echo "ERROR: Specified Python environment not found." 1>&2
        return 1
    fi
    printf "%s\n" "${PYENV_ROOT}/versions/${py_env}/bin"
}

_pypvutil_bin_dir_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_all_completions
    fi
}
complete -o default -F _pypvutil_bin_dir_complete pypvutil_bin_dir
_pypvutil_create_alias "bin_dir" "yes"


pypvutil_bin_ls () {
    local cmd_name
    local py_env="$1"
    if [ -z "$py_env" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "bin_ls")
        cat <<EOF
Usage: $cmd_name PYTHON_ENV [LS_ARGS]

PYTHON_ENV can be a virtualenv or an installed base version.

ERROR: No Python environment given.
EOF
        return 1
    fi
    if ! pypvutil_name_is_global "$py_env" && \
            ! pypvutil_name_is_venv "$py_env"; then
        echo "ERROR: Specified Python environment not found." 1>&2
        return 1
    fi
    shift
    ls "$@" "${PYENV_ROOT}/versions/${py_env}/bin"
}

_pypvutil_bin_ls_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_all_completions
    fi
}
complete -o default -F _pypvutil_bin_ls_complete pypvutil_bin_ls
_pypvutil_create_alias "bin_ls" "yes"


pypvutil_ln () {
    local cmd_name
    local py_env="$1"
    local exec_name="$2"
    local target_dir="$3"
    local source_path
    local target_path

    if [ -z "$py_env" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "ln")
        cat <<EOF
Usage:
[export PYPVUTIL_LN_DIR=SYMLINK_TARGET_DIR]
$cmd_name PYTHON_ENV EXECUTABLE [TARGET_DIR]

PYTHON_ENV can be a virtualenv or an installed base version.

If TARGET_DIR is omitted, it defaults to the value of the PYPVUTIL_LN_DIR
environment variable; if that is unset, it defaults to \
$PYPVUTIL_LN_DIR_DEFAULT_STR.

ERROR: No Python environment given.
EOF
        return 1
    fi
    if ! pypvutil_name_is_global "$py_env" && \
            ! pypvutil_name_is_venv "$py_env"; then
        echo "ERROR: Specified Python environment not found."
        return 1
    fi
    if [ -z "$exec_name" ]; then
        echo "ERROR: No executable name given."
        return 1
    fi
    if [ -z "$target_dir" ]; then
        if [ -n "$PYPVUTIL_LN_DIR" ]; then
            target_dir="$PYPVUTIL_LN_DIR"
        else
            target_dir="$PYPVUTIL_LN_DIR_DEFAULT"
        fi
    fi
    if ! [ -d "$target_dir" ]; then
        echo "ERROR: Target directory doesn't exist or isn't a directory."
        echo "    Target: $target_dir"
        return 1
    fi

    source_path="${PYENV_ROOT}/versions/${py_env}/bin/${exec_name}"
    target_path="${target_dir}/${exec_name}"
    if ln -s "$source_path" "$target_path"; then
        echo "Symlink \"${target_dir}/${exec_name}\" created."
    else
        cat <<EOF

WARNING: Symlink not created.
Source: $source_path
Target: $target_path

EOF
    fi
}

_pypvutil_ln_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_all_completions
    elif [ "$COMP_CWORD" = "2" ]; then
        while read -r line; do
            COMPREPLY+=("$line")
        done < <(pypvutil_bin_ls "${COMP_WORDS[1]}" 2>/dev/null | \
            grep "^${COMP_WORDS[2]}")
        [ -n "$line" ] && COMPREPLY+=("$line")
    fi
}
complete -o default -F _pypvutil_ln_complete pypvutil_ln
_pypvutil_create_alias "ln" "yes"


pypvutil_inst () {
    # replacement for pipsi; creates a pyenv-virtualenv virtualenv
    # specifically for a Python-based utility

    # to remove the virtualenv:
    #rm "${PYPVUTIL_LN_DIR}/EXECUTABLE"
    #pyenv uninstall $package_name-$py_version

    pypvutil_wrapper _pypvutil_inst "$@"
}

_pypvutil_inst () {
    local cmd_name
    local package_name="$1"
    local py_version="$2"
    local package_path="$3"
    local full_name
    local install_string
    local ln_dir_string
    local ln_cmd_name

    if [ -z "$package_name" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "inst")
        cat <<EOF
Usage:
[export PYPVUTIL_LN_DIR=SYMLINK_TARGET_DIR]
$cmd_name PACKAGE_NAME PY_VERSION [PACKAGE_PATH]

If PY_VERSION is 2 or 3, the latest installed Python release with that major
version will be used.
If PYPVUTIL_LN_DIR is not set, SYMLINK_TARGET_DIR defaults to \
$PYPVUTIL_LN_DIR_DEFAULT_STR.

ERROR: No package name given.
EOF
        return 1
    fi
    if [ -z "$py_version" ]; then
        echo "ERROR: No Python version given."
        return 1
    fi

    if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
        if ! py_version=$(pypvutil_latest "$py_version" "installed_only"); then
            # pypvutil_latest will have emitted an error message
            return 1
        fi
    fi
    full_name="${package_name}-${py_version}"

    if ! pypvutil_venv "$package_name" "$py_version"; then
        # error will already have been printed
        return 1
    fi
    pyenv activate "$full_name"
    if [ -z "$package_path" ]; then
        install_string="$package_name"
    else
        install_string="$package_path"
    fi
    if ! pip install "$install_string"; then
        echo
        echo "ERROR: Installation failed.  Stopping."
        echo
        return 1
    fi
    if [ -e "$(pypvutil_bin_dir "${full_name}")/${package_name}" ]; then
        pypvutil_ln "${full_name}" "${package_name}"
    fi
    ln_dir_string=""
    # value for this invocation
    if [ -n "$PYPVUTIL_LN_DIR" ]; then
        ln_dir_string=" \"$PYPVUTIL_LN_DIR\""
    fi
    ln_cmd_name=$(_pypvutil_get_cmd_name "ln")
    cat <<EOF

To symlink other executables:
$ln_cmd_name "${full_name}" "EXECUTABLE"$ln_dir_string

EOF

    return 0
}

_pypvutil_inst_complete () {
    if [ "$COMP_CWORD" = "2" ]; then
        _pypvutil_base_completions pypvutil_bases_installed
        _pypvutil_latest_completions add
    fi
}
complete -o default -F _pypvutil_inst_complete pypvutil_inst
_pypvutil_create_alias "inst" "yes"


pypvutil_copy () {
    # create a new virtualenv based on an existing one, including packages
    pypvutil_wrapper _pypvutil_copy "$@"
}

_pypvutil_copy () {
    local cmd_name
    local source_venv="$1"
    local target_short_name="$2"
    local target_py_version="$3"
    local target_long_name
    if [ -z "$source_venv" ]; then
        cmd_name=$(_pypvutil_get_cmd_name "copy")
        cat <<EOF
Usage: $cmd_name SOURCE_VIRTUALENV TARGET_SHORT_NAME [TARGET_PY_VERSION]

ERROR: No source virtualenv given.
EOF
        return 1
    fi
    if ! pyname_is_venv "$source_venv"; then
        echo "ERROR: Source virtualenv not found."
        return 1
    fi
    if [ -z "$target_short_name" ]; then
        echo "ERROR: No target short name given."
        return 1
    fi
    if [ -z "$target_py_version" ]; then
        target_py_version=$(pypvutil_venv_version "$source_venv")
        if [ -z "$target_py_version" ]; then
            # error already printed
            return 1
        fi
    else
        if [ "$target_py_version" = "2" ] || \
                [ "$target_py_version" = "3" ]; then
            if ! target_py_version=$(pypvutil_latest "$target_py_version" \
                    "installed_only"); then
                # pypvutil_latest will have emitted an error message
                return 1
            fi
        fi
        if ! pypvutil_name_is_global "$target_py_version"; then
            echo "ERROR: Target Python version not found."
            return 1
        fi
    fi
    target_long_name="${target_short_name}-${target_py_version}"
    if pyname_is_venv "$target_long_name"; then
        cat <<EOF
ERROR: Target virtualenv already exists; use pypvutil_pipcopy if you want to
copy just the packages.
EOF
        return 1
    fi

    echo "Creating virtualenv..."
    if ! pypvutil_venv "$target_short_name" "$target_py_version"; then
        # error already printed
        return 1
    fi
    echo "Copying packages..."
    pypvutil_pipcopy "$source_venv" "$target_long_name"
}

_pypvutil_copy_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _pypvutil_venv_completions
    fi
    if [ "$COMP_CWORD" = "3" ]; then
        _pypvutil_base_completions pypvutil_bases_installed
        _pypvutil_latest_completions add
    fi
}
complete -o default -F _pypvutil_copy_complete pypvutil_copy
_pypvutil_create_alias "copy" "yes"
