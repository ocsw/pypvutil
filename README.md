# pypvutil
Utility shell functions to make it easier to work with `pyenv-virtualenv`

# Prerequisites

* [`pyenv`](https://github.com/pyenv/pyenv)
* [`pyenv-virtualenv`](https://github.com/pyenv/pyenv-virtualenv)
* `bash` v3.1+

(These are probably available as packages for your OS.)

## To Use

Configuration involves setting and exporting variables starting with `PYPVUTIL_`.

* Set `PYPVUTIL_HOME` to the directory containing the repo (required)

If you'd like to make the commands start with something other than pypvutil:

* Set `PYPVUTIL_PREFIX` to the prefix you'd like (`pypv` or `py` recommended; optional)
* Source `pypvutil_init.sh`
