# pypvutil

Utility shell functions to make it easier to work with `pyenv-virtualenv`.

## Requirements

* [`pyenv`](https://github.com/pyenv/pyenv)
* [`pyenv-virtualenv`](https://github.com/pyenv/pyenv-virtualenv)
* `bash` v3.1+

Also, `pypvutil_ide_vscode` requires these:

* [The `vscode_setting` function][vscode-script] from
  [this dofiles repo][dotfiles]
* [`jq`][jq]

(Most of these are probably available as packages for your OS.)

[vscode-script]: https://github.com/ocsw/dotfiles/blob/main/dot.bashrc.d/vscode-setting.post.sh
[dotfiles]: https://github.com/ocsw/dotfiles
[jq]: https://github.com/jqlang/jq

## Configuration

Configuration involves setting and exporting variables starting with `PYPVUTIL_`.

### Required Setup

* Set `PYPVUTIL_HOME` to the directory containing the repo

### Optional Setup: Command Prefix

If you'd like to make the commands start with something other than `pypvutil_`:

* Set `PYPVUTIL_PREFIX` to the prefix you'd like (`pypv` or `py` recommended)

## Usage

* Configure (see above)
* Source `pypvutil_init.sh`

## Commands

These assume `PYPVUTIL_PREFIX=py`; otherwise they will be named `pypvutil_act`, etc.

pyact
pyglobal
pylocal
pyide_vscode
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

## Useful Extras

See <https://github.com/ocsw/dotfiles/blob/main/dot.bash_profile.d/python.pre.sh> and <https://github.com/ocsw/dotfiles/blob/main/dot.bashrc.d/python.post.sh> for ways to integrate `pyenv-virtualenv` into your prompt and path and add completion to `pip2` and `pip3`.
