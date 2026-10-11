# dotfiles
Pretty self explanatory.

## Setup

`install.sh` links the configuration in this repo into `$HOME`. It is
idempotent, so a rerun leaves correct links alone and repoints wrong ones.

```sh
./install.sh --dry-run
./install.sh
./install.sh --systemd
./install.sh --desktop-env
./install.sh --desktop-env --personal
./install.sh --sync-wallpaper "$HOME/sync/pictures/wallpapers/FW 13 Pro Wallpaper 7.png"
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

`--sync-wallpaper IMAGE` is a standalone Fedora KDE Plasma operation when used
without other action flags. It sets the desktop and lock-screen wallpaper and
configures Plasma Login to use the same image. `--dry-run` reports the operation
without making changes.

