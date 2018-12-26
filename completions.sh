#!/usr/bin/env bash

###############
# completions #
###############

_py_base_complete () {
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

_py_latest_complete () {
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

_py_venv_complete () {
    local add="$1"
    if [ -z "$add" ]; then
        # seems to not be necessary, but just in case...
        COMPREPLY=()
    fi
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    while read -r line; do
        COMPREPLY+=("$line")
    done < <(pyvenvs | grep "^${cur_word}")
    [ -n "$line" ] && COMPREPLY+=("$line")
}

_py_all_complete () {
    local add="$1"
    if [ -z "$add" ]; then
        # seems to not be necessary, but just in case...
        COMPREPLY=()
    fi
    # bases first, for pyglobal
    _py_base_complete pybases_installed add
    _py_venv_complete add
}
