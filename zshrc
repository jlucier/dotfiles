# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:/snap/bin:/usr/local/go/bin:/home/jordan/.cargo/bin

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  virtualenvwrapper
  virtualenv
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

VIM_SESS_DIR=$HOME/.config/nvim/sessions

_vims_complete() {
  # thanks: https://stackoverflow.com/questions/39624071/autocomplete-in-bash-script

  local file
    # iterate all files in a directory that start with our search string
    for file in $VIM_SESS_DIR/*; do
        # If the glob doesn't match, we'll get the glob itself, so make sure
        # we have an existing file. This check also skips entries
        # that are not a regular file
        [[ -f $file ]] || continue

        # add the file (just filename) to the list of autocomplete suggestions
        COMPREPLY+=( $(basename "$file") )
    done
}

vims () {
  vim -S $VIM_SESS_DIR/${1}
}
complete -F _vims_complete vims

# General
alias grep="grep --color=auto -I --exclude-dir .pytest_cache --exclude-dir .git \
  --exclude-dir __pycache__ --exclude-dir build --exclude-dir '*.egg-info'"
alias desktop='ssh desktop'
alias rsync='rsync -azxvpe ssh --exclude=".git*" --exclude=".*.swp" --exclude="*.pyc" --exclude="*.md" \
    --exclude="*.o" --exclude="*.sqlite3" --exclude="app.db" --exclude="build" --exclude=node_modules \
    --exclude=__pycache__ --exclude=".pytest*" --exclude="*.so" --exclude="*.egg" --exclude="*.egg-info"'
alias sleepmac='pmset sleepnow'
# helps when ssh'ing with alacritty
alias ssh='TERM=xterm-256color ssh'

# git

grmb() {
  git fetch -a --prune
  git branch -D $(git branch -va | grep '\[gone\]' | awk '{ print $1 }' ORS=' '; echo)
}

# Android
export ANDROID_HOME=${HOME}/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export JAVA_HOME=/opt/android-studio/jre

# Virtual Env
export WORKON_HOME=~/.venvs/
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
export VIRTUALENVWRAPPER_SCRIPT=/usr/local/bin/virtualenvwrapper.sh

extra_file=$HOME/.extra_zshrc
if test -f "$extra_file"; then
    source $extra_file
fi
source /usr/local/bin/virtualenvwrapper_lazy.sh

# perch

alias perchgrep="grep -r --exclude-dir hardware_ui --exclude-dir rack_gui \
  --exclude-dir notebooks --exclude-dir perch_webapp --exclude '*.json' --exclude '*.ipynb'"

alias pu="cd ~/perch/perch_utils"
alias fit="cd ~/perch/fitcon5"
alias api="cd ~/perch/perch_api"
alias dcont="cd ~/ext/dev_container"

perchsync () {
  for repo in "fitcon5" "perch_utils" "perch_config"
  do
    rsync --exclude "tests" --exclude "libcomm.c" ${HOME}/perch/${repo} ${1}:~/code
  done
}

revperchsync () {
  for repo in "fitcon5" "perch_utils" "perch_config"
  do
    rsync --exclude "tests" --delete desktop:~/perch/${repo} ${HOME}/perch/
  done
}

hardwaresync () {
  rsync ${HOME}/perch/hardware_ui bigboy:~/catkin_ws/src/
}

docker_sync() {
  rsync --exclude="tests" $HOME/dev/perch_ext/perch_runtime docker-build:~/perch/
}

alias dshell="docker exec -it perch_dev bash -il"

ddev() {
  IMAGE=perchfit/dev_container:latest

  if [ $# -ne 0 ]
  then
    IMAGE=perchfit/dev_container:$1
  fi

  echo Starting $IMAGE

  docker run -it --rm \
    -e DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e PERCH_BUILD_THREADS=8 \
    -e PERCH_BUILD_TYPE=RelWithDebugInfo \
    --cap-add SYS_PTRACE \
    --net=host \
    --ipc=host \
    --gpus all \
    -v $HOME/ext/:/home/perch/ext \
    -v $HOME/dev/dotfiles/docker.bashrc:/home/perch/.bashrc \
    -v $HOME/.ssh:/home/perch/.ssh \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $HOME/.Xauthority:/home/perch/.Xauthority \
    -v $HOME/perch/:/home/perch/code/ \
    -v $HOME/perch/notebooks:/home/perch/perch_notebooks \
    -v $HOME/.aws/:/home/perch/.aws \
    -v $HOME/perch_s3/:/home/perch/perch_s3 \
    -v $HOME/perch_rt_data/:/home/perch/perch_rt_data \
    -v $HOME/profiling/:/home/perch/profiling \
    --name perch_dev \
    $IMAGE
}

cpu_video() {
  docker run -it --rm \
    -e DISPLAY \
    --ipc=host \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    --net host \
    -v $HOME/.Xauthority:/home/perch/.Xauthority \
    -v $HOME/.aws/:/home/perch/.aws \
    -v $HOME/perch_video:/home/perch/perch_video \
    -v $HOME/perch/:/home/perch/code/ \
    --name cpu_video \
    --user root \
    perchfit/dev_container:cpu_video \
    bash -il
}
