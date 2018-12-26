#!/usr/bin/env bash

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
