#!/usr/bin/env bash

####################
# install / create #
####################

pybase () {
    # install a version of Python in pyenv
    local cflags_add="-O2"
    local py_version="$1"

    if [ -z "$py_version" ]; then
        cat <<EOF
Usage: pybase PY_VERSION [PYENV_INSTALL_ARGS]
If PY_VERSION is 2 or 3, the latest available Python release with that major
version will be used.

ERROR: No Python version given.
EOF
        return 1
    fi
    if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
        py_version=$(pylatest "$py_version")
    fi
    shift

    CFLAGS="$cflags_add $CFLAGS" pyenv install "$@" "$py_version"
}

_pybase_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_base_complete pybases_available
        _py_latest_complete add
    fi
}
complete -o default -F _pybase_complete pybase


pyutil_wrapper () {
    # clean up after the Python helpers, below
    local wrapped="$1"
    if [ -z "$wrapped" ]; then
        echo "Usage: pyutil_wrapper COMMAND [ARGS]"
        echo
        echo "ERROR: No command given."
        return 1
    fi

    shift
    local prev_wd="$PWD"
    local prev_venv
    local global_env
    local retval
    prev_venv=$(pycur)

    "$wrapped" "$@"
    retval="$?"

    cd "$prev_wd" || true  # ignore failure
    if [ "$(pycur)" != "$prev_venv" ]; then
        global_env=$(pyenv global)
        if [ "$prev_venv" != "$global_env" ]; then
            pyenv activate "$prev_venv"
        else
            pyenv deactivate
        fi
    fi

    return "$retval"
}


pyfix () {
    # fix a couple of things in a virtualenv that don't seem to come out
    # right by default
    pyutil_wrapper _pyfix "$@"
}

_pyfix () {
    local venv="$1"
    local py_version
    local major
    local major_minor

    if [ -z "$venv" ]; then
        echo "Usage: pyfix VIRTUALENV"
        echo
        echo "ERROR: No virtualenv given."
        return 1
    fi
    if ! pyvenvs | grep "^$venv\$" > /dev/null 2>&1; then
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

_pyfix_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_venv_complete
    fi
}
complete -o default -F _pyfix_complete pyfix

pyfix_all () {
    local venv
    for venv in $(pyvenvs); do
        echo "Fixing virtualenv \"$venv\"..."
        pyfix "$venv"
    done
    echo "Done."
}


pyvenv () {
    # create a pyenv-virtualenv virtualenv with a bunch of tweaks and
    # installs
    pyutil_wrapper _pyvenv "$@"
}

_pyvenv () {
    local short_name="$1"
    local py_version="$2"
    local project_dir="$3"
    local full_name
    local i

    if [ -z "$short_name" ]; then
        cat <<EOF
Usage: pyvenv SHORT_NAME PY_VERSION [PROJECT_DIRECTORY]
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
    if [ -n "$project_dir" ] && [ ! -d "$project_dir" ]; then
        echo "ERROR: Bad project directory."
        return 1
    fi
    if [ -n "$project_dir" ] && \
            ! compgen -G "$project_dir/*requirements.txt" \
            > /dev/null 2>&1; then
        cat <<EOF
ERROR: No requirements files in project directory; try again without it.
EOF
        return 1
    fi

    if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
        py_version=$(pylatest "$py_version" "installed_only")
    fi
    full_name="${short_name}-${py_version}"

    if ! pyenv virtualenv "$py_version" "$full_name"; then
        echo
        echo "ERROR: Can't create virtualenv.  Stopping."
        echo
        return 1
    fi
    pyfix "$full_name"
    if [ -n "$project_dir" ]; then
        pyreqs "$full_name" "$project_dir"
    fi
    cat <<EOF

New Python path:
${PYENV_ROOT}/versions/${full_name}/bin/python

EOF

    return 0
}

_pyvenv_complete () {
    if [ "$COMP_CWORD" = "2" ]; then
        _py_base_complete pybases_installed
        _py_latest_complete add
    fi
}
complete -o default -F _pyvenv_complete pyvenv


pybin_dir () {
    local venv="$1"
    if [ -z "$venv" ]; then
        echo "Usage: pybin_dir VIRTUALENV"
        echo
        echo "ERROR: No virtualenv given."
        return 1
    fi
    printf "%s\n" "${PYENV_ROOT}/versions/${venv}/bin"
}

_pybin_dir_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_venv_complete
    fi
}
complete -o default -F _pybin_dir_complete pybin_dir

pybin_ls () {
    local venv="$1"
    if [ -z "$venv" ]; then
        echo "Usage: pybin_ls VIRTUALENV [LS_ARGS]"
        echo
        echo "ERROR: No virtualenv given."
        return 1
    fi
    shift
    ls "$@" "${PYENV_ROOT}/versions/${venv}/bin"
}

_pybin_ls_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_venv_complete
    fi
}
complete -o default -F _pybin_ls_complete pybin_ls

pyln () {
    local venv="$1"
    local exec_name="$2"
    local target_dir="$3"
    local source_path
    local target_path

    if [ -z "$venv" ]; then
        cat <<EOF
Usage: pyln VIRTUALENV EXECUTABLE TARGET_DIR
If TARGET_DIR is omitted, it defaults to the value of the PYLN_DIR environment
variable; if that is unset, it defaults to \$HOME/bin.

ERROR: No virtualenv given.
EOF
        return 1
    fi
    if [ -z "$exec_name" ]; then
        echo "ERROR: No executable name given."
        return 1
    fi
    if [ -z "$target_dir" ]; then
        if [ -n "$PYLN_DIR" ]; then
            target_dir="$PYLN_DIR"
        else
            target_dir="${HOME}/bin"
        fi
    fi
    if ! [ -d "$target_dir" ]; then
        echo "ERROR: Target directory doesn't exist or isn't a directory."
        echo "    Target: $target_dir"
        return 1
    fi

    source_path="${PYENV_ROOT}/versions/${venv}/bin/${exec_name}"
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

_pyln_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_venv_complete
    elif [ "$COMP_CWORD" = "2" ]; then
    while read -r line; do
        COMPREPLY+=("$line")
    done < <(pybin_ls "${COMP_WORDS[1]}" 2>/dev/null | \
            grep "^${COMP_WORDS[2]}")
    [ -n "$line" ] && COMPREPLY+=("$line")
    fi
}
complete -o default -F _pyln_complete pyln


pyinst () {
    # replacement for pipsi; creates a pyenv-virtualenv virtualenv
    # specifically for a Python-based utility

    # to remove the virtualenv:
    #rm PYLN_DIR/EXECUTABLE
    #pyenv uninstall $package_name-$py_version

    pyutil_wrapper _pyinst "$@"
}

_pyinst () {
    local package_name="$1"
    local py_version="$2"
    local package_path="$3"
    local full_name
    local install_string
    local pyln_dir_string

    if [ -z "$package_name" ]; then
        cat <<EOF
Usage: PYLN_DIR=SYMLINK_TARGET_DIR pyinst PACKAGE_NAME PY_VERSION [PACKAGE_PATH]
If PY_VERSION is 2 or 3, the latest installed Python release with that major
version will be used.
If PYLN_DIR is not set, SYMLINK_TARGET_DIR defaults to \$HOME/bin.

ERROR: No package name given.
EOF
        return 1
    fi
    if [ -z "$py_version" ]; then
        echo "ERROR: No Python version given."
        return 1
    fi

    if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
        py_version=$(pylatest "$py_version" "installed_only")
    fi
    full_name="${package_name}-${py_version}"

    if ! pyvenv "$package_name" "$py_version"; then
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
    if [ -e "$(pybin_dir "${full_name}")/${package_name}" ]; then
        pyln "${full_name}" "${package_name}" "$PYLN_DIR"
    fi
    pyln_dir_string=""
    if [ -n "$PYLN_DIR" ]; then
        pyln_dir_string=" \"$PYLN_DIR\""
    fi
    cat <<EOF

To symlink other executables:
pyln "${full_name}" "EXECUTABLE"$pyln_dir_string

EOF

    return 0
}

_pyinst_complete () {
    if [ "$COMP_CWORD" = "2" ]; then
        _py_base_complete pybases_installed
        _py_latest_complete add
    fi
}
complete -o default -F _pyinst_complete pyinst


pycopy () {
    # create a new virtualenv based on an existing one, including packages
    pyutil_wrapper _pycopy "$@"
}

_pycopy () {
    local source_venv="$1"
    local target_short_name="$2"
    local target_py_version="$3"
    local target_long_name
    if [ -z "$source_venv" ]; then
        cat <<EOF
Usage: pycopy SOURCE_VIRTUALENV TARGET_SHORT_NAME [TARGET_PY_VERSION]

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
        target_py_version=$(pyvenv_version "$source_venv")
        if [ -z "$target_py_version" ]; then
            # error already printed
            return 1
        fi
    else
        if [ "$target_py_version" = "2" ] || \
                [ "$target_py_version" = "3" ]; then
            target_py_version=$(pylatest "$target_py_version" \
                "installed_only")
        fi
        if ! pyname_is_global "$target_py_version"; then
            echo "ERROR: Target Python version not found."
            return 1
        fi
    fi
    target_long_name="${target_short_name}-${target_py_version}"
    if pyname_is_venv "$target_long_name"; then
        cat <<EOF
ERROR: Target virtualenv already exists; use pypipcopy if you want to copy
just the packages.
EOF
        return 1
    fi

    echo "Creating virtualenv..."
    if ! pyvenv "$target_short_name" "$target_py_version"; then
        # error already printed
        return 1
    fi
    echo "Copying packages..."
    pypipcopy "$source_venv" "$target_long_name"
}

_pycopy_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_venv_complete
    fi
    if [ "$COMP_CWORD" = "3" ]; then
        _py_base_complete pybases_installed
        _py_latest_complete add
    fi
}
complete -o default -F _pycopy_complete pycopy
