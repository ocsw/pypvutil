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
