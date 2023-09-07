cdf
===

[![CI](https://github.com/nil-two/cdf/actions/workflows/test.yml/badge.svg)](https://github.com/nil-two/cdf/actions/workflows/test.yml)

Chdir to the favorite directory.

```
$ pwd
/home/user/work/projects/first
$ cdf -a first
(Label the path of the working directory with "first")

$ cd
$ pwd
/home/user

$ cdf first
(Chdir to the directory labeled with "first")
$ pwd
/home/user/work/projects/first
```

Usage
-----

```
usage:
  cdf [--]                         # select a label and chdir to the labeled path
  cdf [--] <label>                 # chdir to the labeled path
  cdf {-a|--add} <label> [<path>]  # label the path (default: working directory)
  cdf {-l|--list}                  # list labels
  cdf {-L|--list-with-paths}       # list labels with paths
  cdf {-p|--print} <label>         # print the labeled path
  cdf {-r|--remove} <label(s)>     # remove labels
  cdf {-w|--wrapper} [<shell>]     # output the wrapper script (default: sh)
  cdf --help                       # print usage

supported-shells:
  sh, bash, zsh, yash, fish

environment-variables:
  CDF_REGISTRY  the registry path (default: ~/.config/cdf/registry.json)
  CDF_FILTER    the interactive filtering command for selecting a label
```

Requirements
------------

- Perl (5.14.0 or later)

Installation
------------

1. Copy `cdf` into your `$PATH`.
2. Make `cdf` executable.
3. Add the following config to your shell's profile.

| Shell |                              |
|-------|------------------------------|
| sh    | eval "$(cdf -w)"             |
| bash  | eval "$(cdf -w bash)"        |
| zsh   | eval "$(cdf -w zsh)"         |
| yash  | eval "$(cdf -w yash)"        |
| fish  | source (cdf -w fish \| psub) |

### Example

```
$ curl -L https://raw.githubusercontent.com/nil-two/cdf/master/cdf > ~/bin/cdf
$ chmod +x ~/bin/cdf
$ echo 'eval "$(cdf -w bash)"' >> ~/.bashrc
```

Note: In this example, `$HOME/bin` must be included in `$PATH`.

Commands
--------

### cdf [--]

Select a label and chdir to the labeled path.
It works only when the shell integration is enabled.

```
$ cdf
(Select a label from labels in the registry, and chdir to the labeled path)
```

### cdf [--] \<label\>

Chdir to the labeled path.
It works only when the shell integration is enabled.

```
$ cdf first
(Chdir to /home/user/work/free/first if /home/user/work/free/first is labeled with "first")

$ cdf home
(Chdir to /home/user if /home/user is labeled with "home")
```

### cdf -a|--add \<label\> [\<path\>]

Label the path.
The default path is the working directory.

```
$ cdf -a work
(Label the working directory with "work")

$ cdf -a bin /home/user/bin
(Label /home/user/bin with "bin")
```

### cdf -l|--list

List labels.

```
$ cdf -l
first
home
```

### cdf -L|--list-with-paths

List labels with paths.

```
$ cdf -L
first	/home/user/work/free/first
home	/home/user
```

### cdf -p|--print \<label\>

Print the labeled path.

```
$ cdf -p first
/home/user/work/free/first

$ cdf -p home
/home/user
```

### cdf -r|--remove \<label(s)\>

Remove labels.

```
$ cdf -r home
(Remove "home" in the registry)

$ cdf -r first home
(Remove "first" and "home" in the registry)
```

### cdf -w|--wrapper [\<shell\>]

Print the wrapper script.
The default shell is `sh`.

Supported shells are as follows:

- sh
- bash
- zsh
- yash
- fish

```
$ eval "$(cdf -w)"
(Enable the shell integration for the shell compatible with Bourne Shell)

$ eval "$(cdf -w bash)"
(Enable the shell integration for Bash)

$ eval "$(cdf -w zsh)"
(Enable the shell integration for Zsh)

$ eval "$(cdf -w yash)"
(Enable the shell integration for Yash)

$ source (cdf -w fish | psub)
(Enable the shell integration for Fish)
```

### cdf --help

Print usage.

```
$ cdf -h
(Print usage)
```

Variables
---------

### `CDF_REGISTRY`

The path of the registry file.
The default value is `$HOME/.config/cdf/registry.json`.

The structure of JSON is as follows:

```
{
  "version": "<registry-version>",
  "labels": {
    "<label1>": "<path1>",
    "<label2>": "<path2>",
    ...
  }
}
```

### `CDF_FILTER`

The command to use select a label.
The default value is `percol`.

```
# Use fzy to select the label
export CDF_FILTER=fzy

# Use fzf with preview to select the label
export CDF_FILTER='fzf --layout=reverse --preview='"'"'printf "# %s\n" {}; cdf --print {}'"'"''
```

License
-------

MIT License

Author
------

nil2 <nil2@nil2.org>
