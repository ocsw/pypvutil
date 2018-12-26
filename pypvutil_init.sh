#!/usr/bin/env bash

if [ -z "$PYPVUTIL_HOME" ]; then
    echo
    echo "ERROR: $PYPVUTIL_HOME is unset."
    echo
    return 1
fi
if [ ! -d "$PYPVUTIL_HOME" ]; then
    echo
    echo "ERROR: $PYPVUTIL_HOME is not a directory."
    echo
    return 1
fi

for i in get_current completions set_current create update delete; do
    # shellcheck disable=SC1090
    . "${PYPVUTIL_HOME}/${i}.sh"
done
