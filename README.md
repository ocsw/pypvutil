# pypvutil

Utility shell functions to make it easier to work with `pyenv-virtualenv`.

## Prerequisites

* [`pyenv`](https://github.com/pyenv/pyenv)
* [`pyenv-virtualenv`](https://github.com/pyenv/pyenv-virtualenv)
* `bash` v3.1+

(These are probably available as packages for your OS.)

## Configuration

Configuration involves setting and exporting variables starting with `PYPVUTIL_`.

### Required:

* Set `PYPVUTIL_HOME` to the directory containing the repo

### Optional:

If you'd like to make the commands start with something other than `pypvutil_`:

* Set `PYPVUTIL_PREFIX` to the prefix you'd like (`pypv` or `py` recommended)

## Usage

* Configure (see above)
* Source `pypvutil_init.sh`

## Commands

These assume `PYPVUTIL_PREFIX=py`; otherwise they will be named `pypvutil_act`, etc.

pyact
pyglobal
pybase
pywrapper
pyfix
pyfix_all
pyvenv
pybin_dir
pybin_ls
pyln
pyinst
pycopy
pycur
pycur_is_global
pycur_is_venv
pycur_is_dotfile
pybases_available
pybases_installed
pyvenvs
pyname_is_global
pyname_is_venv
pylatest
pylatest_local
pyvenv_version
pyreqs
pypipcopy
pyrm
