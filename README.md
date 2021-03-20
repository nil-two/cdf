cdf
===

![CI](https://github.com/kusabashira/cdf/workflows/CI/badge.svg)

Chdir to the favorite directory.

```
$ pwd
/home/user/work/projects/first
$ cdf -a first
(save the path of current directory with label "first")

$ cd
$ pwd
/home/user

$ cdf first
(chdir to the directory labeled "first")
$ pwd
/home/user/work/projects/first
```

Usage
-----

```
usage:
  cdf [--] <label>         # chdir to the path so labeled
  cdf -a <label> [<path>]  # save the path with the label
  cdf -g <label>           # get the path so labeled
  cdf -l                   # list labels
  cdf -r <label(s)>        # remove labels
  cdf -w [<shell>]         # output the wrapper script (default: sh)
  cdf -h                   # print usage

supported-shells:
  sh, ksh, bash, zsh, yash, fish, tcsh, rc,
  nyagos, xyzsh, xonsh, eshell, cmd, powershell

environment-variables:
  CDFFILE  # the registry path (default: ~/.config/cdf/cdf.json)
```

Requirements
------------

- Perl (5.14.0 or later)

Installation
------------

1. Copy `cdf` into your `$PATH`.
2. Make `cdf` executable.
3. Add following config to your shell's rc file.

| Shell      |                                                                                           |
|------------|-------------------------------------------------------------------------------------------|
| sh         | eval "$(cdf -w)"                                                                          |
| ksh        | eval "$(cdf -w ksh)"                                                                      |
| bash       | eval "$(cdf -w bash)"                                                                     |
| zsh        | eval "$(cdf -w zsh)"                                                                      |
| yash       | eval "$(cdf -w yash)"                                                                     |
| fish       | source (cdf -w fish \| psub)                                                              |
| tcsh       | cdf -w tcsh \| source /dev/stdin; true                                                    |
| rc         | ifs='' eval \`{cdf -w rc}                                                                 |
| nyagos     | lua\_e "loadstring(nyagos.eval(""cdf -w nyagos""))()"                                     |
| xyzsh      | eval "$(sys::cdf -w xyzsh)"                                                               |
| xonsh      | execx($(cdf -w xonsh))                                                                    |
| eshell     | (eval (car (read-from-string (shell-command-to-string "cdf -w eshell"))))                 |
| cmd        | perl {{path to cdf}} -w cmd > %homepath%\\.cdf.bat<br>doskey cdf=%homepath%\\.cdf.bat $\* |
| powershell | Invoke-Expression (@(perl {{path to cdf}} -w powershell) -join "`n")                      |

### Example

```
$ curl -L https://raw.githubusercontent.com/kusabashira/cdf/master/cdf > ~/bin/cdf
$ chmod +x ~/bin/cdf
$ echo 'eval "$(cdf -w bash)"' >> ~/.bashrc
```

Note: In this example, `$HOME/bin` must be included in `$PATH`.

Commands
--------

### cdf [--] \<label\>

Chdir to the path so labeled.

```
$ cdf home
(Chdir to /home/user if /home/user is labeled home)

$ cdf go
(Chdir to /home/user/work/dev/go/github.com/user if /home/user/work/dev/go/github.com/user is labeled go)
```

### cdf -a \<label\> [\<path\>]

Save the path with the label.
If the path is ommited, the path will be the current working directory.

```
$ cdf -a work
(Save the current working directory as work)

$ cdf -a bin /home/user/bin
(Save the /home/user/bin as bin)
```

### cdf -g \<label\>

Print the path so labeled.

```
$ cdf -g home
/home/user
(Print if /home/user is labeled home)

$ cdf -g go
/home/user/work/dev/go/github.com/user 
(Print if /home/user/work/dev/go/github.com/user is labeled go)
```

### cdf -l

List labels.

```
$ cdf -l
go
home
(If only the path labeled home and the path labeled go exist)
```

### cdf -r \<label(s)\>

Remove labels.

```
$ cdf -r home
(Remove the path labeled home)

$ cdf -r go go2
(Remove the pathes labeled go and go2)
```

### cdf -w [\<shell\>]

Output the wrapper script.
If shell specified, it outputs wrapper script optimized for the shell.

Supported shells are as follows:

- sh
- ksh
- bash
- zsh
- yash
- fish
- tcsh
- rc
- nyagos
- xyzsh
- xonsh
- eshell
- cmd
- powershell

```
$ eval "$(cdf -w)"
(Enable the shell integration for the shell compatible with Bourne Shell)

$ eval "$(cdf -w ksh)"
(Enable the shell integration for ksh)

$ eval "$(cdf -w bash)"
(Enable the shell integration for bash)

$ eval "$(cdf -w zsh)"
(Enable the shell integration for zsh)

$ eval "$(cdf -w yash)"
(Enable the shell integration for yash)

$ source (cdf -w fish | psub)
(Enable the shell integration for fish)

$ cdf -w tcsh | source /dev/stdin; true
(Enable the shell integration for tcsh)

$ ifs='' eval `{cdf -w rc}
(Enable the shell integration for rc)

$ lua_e "loadstring(nyagos.eval(""cdf -w nyagos""))()"
(Enable the shell integration for nyagos)

$ eval "$(sys::cdf -w xyzsh)"
(Enable the shell integration for xyzsh)

$ execx($(cdf -w xonsh))
(Enable the shell integration for xonsh)

$ (eval (car (read-from-string (shell-command-to-string "cdf -w eshell"))))
(Enable the shell integration for eshell)

$ perl {{path to cdf}} -w cmd > %homepath%\.cdf.bat
$ doskey cdf=%homepath%\.cdf.bat $*
(Enable the shell integration for cmd)

$ Invoke-Expression (@(perl {{path to cdf}} -w powershell) -join "`n")
(Enable the shell integration for powershell)
```

### cdf -h

Print usage.

```
$ cdf -h
(Print usage)
```

Variables
---------

### CDFFILE

The path of the registry file.
Default value is `$HOME/.config/cdf/cdf.json`.

The structure of JSON is as follows:

```
{
  "<label1>": "<path1>",
  "<label2>": "<path2>",
  ...
}
```

License
-------

MIT License

Author
------

nil2 <nil2@nil2.org>
