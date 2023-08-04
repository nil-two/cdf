cdf
===

![CI](https://github.com/nil-two/cdf/workflows/CI/badge.svg)

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
  cdf [--]                         # select label and chdir to the labeled path
  cdf [--] <label>                 # chdir to the labeled path
  cdf {-a|--add} <label> [<path>]  # label the path (default: working directory)
  cdf {-l|--list}                  # list labels
  cdf {-L|--list-with-paths}       # list labels with paths
  cdf {-p|--print} <label>         # print the labeled path
  cdf {-r|--remote} <label(s)>     # remove labels
  cdf {-w|--wrapper} [<shell>]     # output the wrapper script (default: sh)
  cdf --help                       # print usage

supported-shells:
  sh, bash

environment-variables:
  CDF_REGISTRY  the registry path (default: ~/.config/cdf/registry.json)
  CDF_FILTER    the intractive filtering command for selecting label
```

Requirements
------------

- Perl (5.14.0 or later)

Installation
------------

1. Copy `cdf` into your `$PATH`.
2. Make `cdf` executable.
3. Add following config to your shell's rcfile.

| Shell |                              |
|-------|------------------------------|
| sh    | eval "$(cdf -w)"             |
| bash  | eval "$(cdf -w bash)"        |
| zsh   | eval "$(cdf -w zsh)"         |
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
(Remove the paths labeled go and go2)
```

### cdf -w [\<shell\>]

Output the wrapper script.
If shell specified, it outputs wrapper script optimized for the shell.

Supported shells are as follows:

- sh
- bash
- zsh
- fish

```
$ eval "$(cdf -w)"
(Enable the shell integration for the shell compatible with Bourne Shell)

$ eval "$(cdf -w bash)"
(Enable the shell integration for bash)

$ eval "$(cdf -w zsh)"
(Enable the shell integration for zsh)

$ source (cdf -w fish | psub)
(Enable the shell integration for fish)
```

### cdf -h

Print usage.

```
$ cdf -h
(Print usage)
```

Variables
---------

### `CDF_REGISTRY`

The path of the registry file.
Default value is `$HOME/.config/cdf/registry.json`.

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

License
-------

MIT License

Author
------

nil2 <nil2@nil2.org>
