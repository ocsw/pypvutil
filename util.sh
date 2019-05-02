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

_pypvutil_err () {
    _pypvutil_diag "ERROR: " "$@"
}

_pypvutil_warn () {
    _pypvutil_diag "WARNING: " "$@"
}

_pypvutil_diag () {
    # Print diagnostic output.
    #
    # Available values for diag_style:
    # - "short" (the default) just prints the diagnostic string
    # - "long" surrounds it with blank lines
    # - "usage_diag" prints the usage string, then a blank line, then the
    #   diagnostic string
    # - "usage_only" prints only the usage string (pass "" for the diag_prefix
    #   and diag_string)

    diag_prefix="$1"
    diag_string="$2"
    diag_style="$3"
    usage_string="$4"

    if [ -z "$diag_prefix" ]; then
        echo "WARNING: No diag prefix given to _pypvutil_diag()." 1>&2
    fi
    if [ -z "$diag_string" ]; then
        echo "WARNING: No diag string given to _pypvutil_diag()." 1>&2
    fi
    if [ -z "$diag_style" ]; then
        echo "WARNING: No diag style given to _pypvutil_diag()." 1>&2
    fi
    if [ "$diag_style" = "usage" ] && [ -z "$usage_string" ]; then
        echo "WARNING: No usage string given to _pypvutil_diag()." 1>&2
    fi

    if [ "$diag_style" = "usage" ]; then
        printf "%s\n" "$usage_string" 1>&2
        echo 1>&2
    fi
    [ "$diag_style" = "long" ] && echo 1>&2
    printf "%s\n" "${diag_prefix}${diag_string}" 1>&2
    [ "$diag_style" = "long" ] && echo 1>&2

    # explicitly return 0 so we are guaranteed to be able to do
    # '! cmd && _pypvutil_diag foo short && return 1'
    return 0
}

_pypvutil_create_alias () {
    function_shortname="$1"
    alias_completion="$2"

    if [ -z "$PYPVUTIL_PREFIX" ]; then
        return 0
    fi
    if [ -z "$function_shortname" ]; then
        _pypvutil_err "ERROR: No function shortname given to create_alias()." \
            short && return 1
    fi

    function_fullname="pypvutil_${function_shortname}"
    completion_function=""
    if [ "$alias_completion" = "yes" ]; then
        completion_function="_${function_fullname}_complete"
    fi

    # shellcheck disable=SC2139
    alias "${PYPVUTIL_PREFIX}${function_shortname}=$function_fullname"
    if [ -n "$completion_function" ]; then
        complete -o default -F "$completion_function" \
            "${PYPVUTIL_PREFIX}${function_shortname}"
    fi
}

_pypvutil_get_cmd_name () {
    function_shortname="$1"

    if [ -z "$function_shortname" ]; then
        _pypvutil_err \
"ERROR: No function shortname given to _pypvutil_get_cmd_name()." short
        echo "CMD_NAME"
        return 1
    fi

    if [ -n "$PYPVUTIL_PREFIX" ]; then
        printf "%s\n" "${PYPVUTIL_PREFIX}${function_shortname}"
    else
        printf "%s\n" "pypvutil_${function_shortname}"
    fi
}
