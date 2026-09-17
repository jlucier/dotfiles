# dotfiles
Pretty self explanatory.

## Setup

`install.sh` links the configuration in this repo into `$HOME`. It is
idempotent, so a rerun leaves correct links alone and repoints wrong ones.

```sh
./install.sh --dry-run        # report the changes, write nothing
./install.sh                  # create the links
./install.sh --systemd        # also link the systemd user units
./install.sh --desktop-env    # also install programs and apply Plasma settings
./install.sh --desktop-env --personal   # also Discord and Steam
```

The systemd user units (`supernote`, `meeting-followups`) are Linux only and
opt in, because those timers suit a desktop that runs all the time. `--systemd`
only links them. To enable them, see `supernote/README.md` and
`meeting-followups/README.md`.

`--desktop-env` works on Fedora KDE Plasma only. It runs
`fedora/kde/install.sh` (packages, flatpaks, fonts, a ghostty build, oh-my-zsh,
tpm, the AI tools) before the links, and `fedora/kde/plasma.sh` (Caps Lock as
Meta, five virtual desktops, global shortcuts) after them. Both scripts are
idempotent and can run on their own. Shortcut changes take effect after a
logout.

The bspwm desktop (`config/bspwm`, `config/polybar`, `config/picom.conf`) and
`fedora/bspwm/` stay in the repo, but `install.sh` ignores them.
`fedora/bspwm/install.sh` takes a Fedora server install to that desktop.
