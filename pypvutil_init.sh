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

if [ -z "$PYPVUTIL_HOME" ]; then
    echo "ERROR: PYPVUTIL_HOME is unset." 1>&2
    return 1
fi
if ! [ -d "$PYPVUTIL_HOME" ]; then
    echo "ERROR: PYPVUTIL_HOME is not a directory." 1>&2
    return 1
fi
# in case it was only a shell variable; probably not necessary, but it'll
# protect against errors involving subshells
export PYPVUTIL_HOME

export PYPVUTIL_LN_DIR_DEFAULT="${HOME}/bin"
export PYPVUTIL_LN_DIR_DEFAULT_STR="\${HOME}/bin"
if [ -z "$PYPVUTIL_LN_DIR" ]; then
    PYPVUTIL_LN_DIR="$PYPVUTIL_LN_DIR_DEFAULT"
fi
export PYPVUTIL_LN_DIR

export PYPVUTIL_PREFIX

for i in util get_current completions set_current create update delete; do
    # shellcheck disable=SC1090
    . "${PYPVUTIL_HOME}/${i}.sh"
done
