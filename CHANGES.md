### v2.7.2 - 2020-02-22

- Change shebang from `#!/usr/bin/perl` to `#!/usr/bin/env perl`
- Fix broken ksh-wrapper

### v2.7.1 - 2020-02-22

- Support Bash3.x

### v2.7.0 - 2019-05-18

- Support xyzsh

### v2.6.1 - 2019-05-18

- Escape spaces and special characters in bash-completion
- Escape spaces and special characters in zsh-completion
- Escape spaces and special characters in yash-completion
- Escape spaces and special characters in nyagos-completion
- Avoid word-splitting in xonsh-completion
- Allow "cdf -w tcsh | source /dev/stdin" without "unalias cdf" in tcsh
- Unify exitcodes to 1 on failure

### v2.6.0 - 2019-05-03

- Support cmd.
- Support powershell.

### v2.5.0 - 2019-04-28

- Allow removing multipe labels at once.
- Stop accessing to \_\_xonsh\_\_ in xonsh-wrapper.
- Support ksh.

### v2.4.0 - 2019-04-28

- Support xonsh.

### v2.3.0 - 2019-04-27

- Support rc.

### v2.2.0 - 2019-04-25

- Support nyagos.

### v2.1.0 - 2019-04-24

- Support tcsh.

### v2.0.0 - 2019-04-14

- Change the default location of CDFFILE from `~/.local/share/cdf/cdf.json` to `~/.config/cdf/cdf.json`.

### v1.1.0 - 2019-04-14

- Support yash.
- Support fish.

### v1.0.0 - 2019-01-05

- Initial release.
