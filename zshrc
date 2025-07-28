# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="jlucier"
HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"

plugins=(
  git
)

source $ZSH/oh-my-zsh.sh

unsetopt INC_APPEND_HISTORY
unsetopt SHARE_HISTORY
setopt APPEND_HISTORY

# If I type cd and then cd again, only save the last one
setopt HIST_IGNORE_DUPS

# Even if there are commands inbetween commands that are the same, still only save the last one
setopt HIST_IGNORE_ALL_DUPS

# Pretty    Obvious.  Right?
setopt HIST_REDUCE_BLANKS

# If a line starts with a space, don't save it.
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE

# When using a hist thing, make a newline show the change before executing it.
setopt HIST_VERIFY

# Save the time and how long a command ran
setopt EXTENDED_HISTORY

setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# Vim (rather, Neovim)

export VISUAL=nvim
export EDITOR=$VISUAL
alias vim='nvim'

# General
alias clip="xclip -selection clipboard"
alias grep="grep --color=auto -I --exclude-dir .pytest_cache --exclude-dir .git \
  --exclude-dir __pycache__ --exclude-dir build --exclude-dir '*.egg-info'"
alias rsync='rsync -azxvpe ssh --exclude=".git*" --exclude=".*.swp" --exclude="*.pyc" --exclude="*.md" \
    --exclude="*.o" --exclude="*.sqlite3" --exclude="app.db" --exclude="build" --exclude=node_modules \
    --exclude=__pycache__ --exclude=".pytest*" --exclude="*.cpython*.so" --exclude="*.egg" \
    --exclude="*.egg-info" --exclude="**/*.DS_Store"'
# helps when ssh'ing with alacritty
alias ssh='TERM=xterm-256color ssh'
alias tmux='TERM=xterm-256color tmux'
alias t='tmux'
alias tl='tmux list-s'
alias ta='tmux a'

# git
alias gs="gst"

grmb() {
  git fetch -a --prune
  git branch -D $(git branch -va | grep '\[gone\]' | awk '{ print $1 }' ORS=' '; echo)
}

export PATH="$HOME/.local/bin:$PATH:/usr/local/go/bin"
export NVM_DIR="$HOME/.nvm"

nvmload() {
  # these slow down terminal launch a lot, so I moved them to a function
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

extra_file=$HOME/.extra_zshrc
if test -f "$extra_file"; then
    source $extra_file
fi

# perch
if [ -f $HOME/.perchrc ]; then
    source $HOME/.perchrc
fi

# zoxide
eval "$(zoxide init zsh)"
alias cd="z"

wakedt() {
  reqstatus=$(curl -s -o /dev/null -w "%{http_code}" http://192.168.13.99/power)

  if [ $reqstatus -eq 200 ]; then
    echo "OK"
  else
    echo "Not OK (status: $reqstatus)"
  fi
}
