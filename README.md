# dotfiles
Pretty self explanatory.

## Setup

`install.sh` links the configuration in this repo into `$HOME`. It is
idempotent, so a rerun leaves correct links alone and repoints wrong ones.

```sh
./install.sh --dry-run   # report the changes, write nothing
./install.sh             # create the links
./install.sh --systemd   # also link the systemd user units
```

The systemd user units (`supernote`, `meeting-followups`) are Linux only and
opt in, because those timers suit a desktop that runs all the time. `--systemd`
only links them. To enable them, see `supernote/README.md` and
`meeting-followups/README.md`.

The bspwm desktop (`config/bspwm`, `config/polybar`, `config/picom.conf`) and
`fedora/install.sh` stay in the repo, but `install.sh` ignores them.
`fedora/install.sh` takes a Fedora server install to that desktop.
