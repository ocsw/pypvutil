#!/usr/bin/env bash

#####################
# get current state #
#####################

pycur () {
    printf "%s\n" "$(pyenv version | sed 's/ (.*$//')"
}

pycur_is_global() {
    [ -z "$PYENV_VERSION" ] && [ -z "$PYENV_VIRTUAL_ENV" ]
}

pycur_is_venv() {
    [ -n "$PYENV_VERSION" ] && [ -n "$PYENV_VIRTUAL_ENV" ]
}

pycur_is_dotfile () {
    [ -z "$PYENV_VERSION" ] && [ -n "$PYENV_VIRTUAL_ENV" ]
}

pybases_available () {
    pyenv install --list | tail -n +2 | sed 's/^..//'
}

pybases_installed () {
    # see:
    # https://unix.stackexchange.com/questions/275637/limit-posix-find-to-specific-depth
    find "${PYENV_ROOT}/versions/." ! -name . -prune -type d | \
        sed "s|^${PYENV_ROOT}/versions/\./||"
}

pyvenvs () {
    pyenv virtualenvs | sed -e 's/^..//' -e 's/ (.*$//' | \
        grep -v "/envs/"
}

pyname_is_global () {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Usage: pyname_is_global NAME"
        echo
        echo "ERROR: No name given."
        return 1
    fi
    pybases_installed | grep "^${name}\$" > /dev/null 2>&1
}

pyname_is_venv () {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Usage: pyname_is_venv NAME"
        echo
        echo "ERROR: No name given."
        return 1
    fi
    pyvenvs | grep "^${name}\$" > /dev/null 2>&1
}

pylatest () {
    # get the latest available (or latest locally installed) version of
    # Python for a specified major version in pyenv
    local major_version="$1"
    local installed_only="$2"
    local versions ver

    if [ -n "$major_version" ] && [ "$major_version" != "2" ] && \
            [ "$major_version" != "3" ]; then
        cat <<EOF
Usage: pylatest [MAJOR_PY_VERSION] [INSTALLED_ONLY]
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
    # https://web.archive.org/web/20090208232311/http://student.northpark.edu/pemente/awk/awk1line.txt
    versions=$(pyenv install --list | tail -n +2 | sed 's/^..//' | \
        grep "^${major_version}\.[0-9]" | grep -vi "[a-z]" | \
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

    return 1
}

# don't use aliases so no other args will be passed
py3latest () { pylatest 3; }
py2latest () { pylatest 2; }
pylatest_local () { pylatest "$1" "installed_only"; }
py3latest_local () { pylatest_local 3; }
py2latest_local () { pylatest_local 2; }

pyvenv_version () {
    # get the version of a virtualenv; don't rely on the name
    local venv="$1"
    local py_version
    if [ -z "$venv" ]; then
        echo "Usage: pyvenv_version VIRTUALENV"
        echo
        echo "ERROR: No virtualenv given."
        return 1
    fi
    if ! pyname_is_venv "$venv"; then
        echo "ERROR: Virtualenv not found."
        return 1
    fi

    py_version=$(pyenv versions | sed -e 's/^..//' -e 's/ (.*$//' | \
        grep "/envs/${venv}\$" | sed 's|/.*$||')
    if [ -z "$py_version" ]; then
        echo
        echo "ERROR: Can't get version for virtualenv."
        echo
        return 1
    fi
    printf "%s\n" "$py_version"
}

_pyvenv_version_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_venv_complete
    fi
}
complete -o default -F _pyvenv_version_complete pyvenv_version
