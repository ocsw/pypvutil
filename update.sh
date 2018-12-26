#!/usr/bin/env bash

###################
# update / change #
###################

pyreqs () {
    # install a project's requirements in a pyenv-virtualenv virtualenv
    pyutil_wrapper _pyreqs "$@"
}

_pyreqs () {
    local venv="$1"
    local project_dir="$2"
    local i

    if [ -z "$venv" ]; then
        echo "Usage: pyreqs VIRTUALENV PROJECT_DIRECTORY"
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

_pyreqs_complete () {
    if [ "$COMP_CWORD" = "1" ]; then
        _py_venv_complete
    fi
}
complete -o default -F _pyreqs_complete pyreqs


pypipcopy () {
    # add the packages from one virtualenv to another virtualenv
    pyutil_wrapper _pypipcopy "$@"
}

_pypipcopy () {
    local source_venv="$1"
    local target_venv="$2"
    local reqs_file
    if [ -z "$source_venv" ]; then
        echo "Usage: pypipcopy SOURCE_VIRTUALENV TARGET_VIRTUALENV"
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

_pypipcopy_complete () {
    if [ "$COMP_CWORD" = "1" ] || [ "$COMP_CWORD" = "2" ]; then
        _py_venv_complete
    fi
}
complete -o default -F _pypipcopy_complete pypipcopy
