# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:/snap/bin:/usr/local/go/bin

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
# HYPHEN_INSENSITIVE="true"

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
# COMPLETION_WAITING_DOTS="true"

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
alias grep='grep --color=auto -I'
alias desktop='ssh desktop'
alias rsync='rsync -azxvpe ssh --exclude=".git*" --exclude=".*.swp" --exclude="*.pyc" --exclude="*.md" \
    --exclude="*.o" --exclude="*.sqlite3" --exclude="app.db" --exclude="build" --exclude=node_modules \
    --exclude=__pycache__ --exclude=".pytest*" --exclude="*.so"'
alias sleepmac='pmset sleepnow'

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

#
# perch

alias instance='python ~/perch/perch_scripts/dev/instance_management.py'
alias perchgrep="grep -rI --exclude-dir .git --exclude-dir build --exclude-dir .pytest_cache \
    --exclude-dir '*.egg-info' --exclude-dir __pycache__ --exclude-dir hardware_ui \
    --exclude-dir perch_api --exclude-dir rack_gui --exclude-dir notebooks --exclude-dir perch_webapp"


perchsync () {
  for repo in "fitcon5" "perch_utils" "perch_config"
  do
    rsync --exclude "tests" --exclude "libcomm.c" ${HOME}/perch/${repo} ${1}:~/catkin_ws/src/
  done
}

otherperchsync() {
  for repo in "videoplayer" "perch_utils" "perch_config" "perch_scripts" "perch_data"
  do
    rsync --exclude "tests" ${HOME}/perch/${repo} ${1}:~/catkin_ws/src/
  done
}

perchmlsync () {
  for repo in "fitcon5" "perch_utils" "perch_config" "perch_ml" "perch_data" "videoplayer"
  do
    rsync --exclude "tests" ${HOME}/perch/${repo} ${1}:~/catkin_ws/src/
  done
}

revperchsync () {
  for repo in "fitcon5" "perch_utils" "perch_config"
  do
    rsync --exclude "tests" --delete desktop:~/perch/${repo} ${HOME}/perch/
  done
}

otherrevperchsync () {
  for repo in "videoplayer" "perch_utils" "perch_config" "perch_scripts" "perch_data"
  do
    rsync --exclude "tests" desktop:~/perch/${repo} ${HOME}/perch/
  done
}


perchdevsync () {
  for repo in "fitcon5" "perch_utils" "perch_config" "perch_data" "videoplayer" "perch_testing"
  do
    rsync --exclude "tests" ${HOME}/perch/${repo} ${1}:~/catkin_ws/src/
  done
}

revperchdevsync () {
  for repo in "fitcon5" "perch_utils" "perch_config" "perch_data" "videoplayer" "perch_testing"
  do
    rsync --exclude "tests" personal:~/perch/${repo} ${HOME}/perch/
  done
}

gpusync () {
  for repo in "perch_utils" "perch_data" "perch_config"
  do
    rsync --exclude "tests" ${HOME}/perch/${repo} ${1}:~/perch/
  done
}

hardwaresync () {
  rsync ${HOME}/perch/hardware_ui bigboy:~/catkin_ws/src/
}

ssh_unit() {
    PASS=$(python ${HOME}/perch/perch_scripts/units/get_password.py -n $1)
    ssh -tt perchproxy sshpass -p $PASS ssh nvidia@localhost -p $2
}

docker_sync() {
  rsync $HOME/perch/perch_runtime docker-build:~/perch/
}

docker_dev() {
    docker run -it --rm \
        -e DISPLAY \
        --ipc=host \
        --gpus all \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        --net host \
        -v $HOME/.Xauthority:/home/perch/.Xauthority \
        -v $HOME/perch/:/home/perch/code/ \
        -v $HOME/.aws/:/home/perch/.aws \
        -v $HOME/perch_rt_data/:/home/perch/perch_rt_data \
        -v $HOME/profiling/:/home/perch/profiling \
        -v $HOME/perch_datasets:/home/perch/perch_datasets \
        -v $HOME/perch_networks:/home/perch/perch_networks \
        -v $HOME/perchreleases:/home/perch/perchreleases \
        -v $HOME/perch_sim_data:/home/perch/perch_sim_data \
        -v $HOME/perch_sim_objects:/home/perch/perch_sim_objects \
        -v $HOME/perch_updates:/home/perch/perch_updates \
        -v $HOME/perch_video:/home/perch/perch_video \
        --name perch_dev \
        perchfit/dev_container:latest
}

garden_sync() {
    rsync ~/dev/garden-pi/api garden:~/garden-pi/
    scp -r ~/dev/garden-pi/frontend/build garden:~/garden-pi/frontend/build
}
