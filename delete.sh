#!/usr/bin/env bash

##########
# delete #
##########

# wrap 'pyenv uninstall' for convenience, preserving autocomplete
pyrm () {
    pyenv uninstall "$@"
}

_pyrm_complete () {
    local cur_word="${COMP_WORDS[$COMP_CWORD]}"
    if [ "$COMP_CWORD" = "1" ] || [ "$COMP_CWORD" = "2" ]; then
        COMPREPLY=()
        if [[ "--force" =~ ^$cur_word ]] || [[ "-f" =~ ^$cur_word ]]; then
            COMPREPLY+=("--force")
        fi
        _py_all_complete add
    fi
}
complete -o default -F _pyrm_complete pyrm
