# .bashrc
# vim: ft=sh
# Delivered through puppet, local changes will be stomped.

[ -z "$PS1" ] && return

export LC_ALL=en_US.utf8

tput &>/dev/null ; retval=$?
if [[ $retval == 3 ]]; then
	echo tput does not know your terminal \"$TERM\"
fi

# Source global definitions
[ -f /etc/bash/bashrc ] && source /etc/bash/bashrc

# From /etc/bash.bashrc (where it is commented-out)
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

alias ls="ls --color=tty"
eval $(dircolors)
export LS_COLORS=${LS_COLORS/di=01;34/di=36}
export LESSCHARSET="UTF-8"
export ACK_COLOR_MATCH="bold red"

shopt -s checkhash    # disable need for hash -r
shopt -s checkjobs    # Show suspended jobs on ^D
shopt -s checkwinsize # Check term size after each command
shopt -s cmdhist
shopt -s execfail
shopt -s expand_aliases
shopt -s histreedit
shopt -s histverify   # do not execute histexpansion directly, preload cmdline
shopt -s no_empty_cmd_completion # do not complete on tab with empty cmdline

# Bash history format/size
export HISTTIMEFORMAT="%Y-%m-%dT%H:%M:%S%z "
export HISTCONTROL="ignorespace:ignoredups"
export HISTSIZE=-1
export HISTFILESIZE=-1

PATH=$HOME/bin:$HOME/.local/bin:$PATH:/sbin:/usr/sbin

if [ "$SSH_CLIENT" != "" ]; then
  HN="\h "
fi

if [[ -f /etc/bash_completion.d/git-prompt ]]; then # Debian
    export GIT_PS1_SHOWDIRTYSTATE="yes"
    export GIT_PS1_SHOWSTASHED="yes"
    export GIT_PS1_SHOWUNTRACKEDFILES="yes"
    export GIT_PS1_SHOWUPSTREAM="auto"
    export GIT_PS1_SHOWCOLORHINTS="yes"
    . /etc/bash_completion.d/git-prompt
    gitps="__git_ps1"
else
    gitps=":"
fi

PROMPTCOLOR="\[$(tput setaf 3)\]\[$(tput bold)\]"
PROMPTRESET="\[$(tput sgr0)\]"
case ${TERM} in
    xterm*|rxvt*|Eterm|aterm|kterm|gnome)
        export PS1="$PROMPTCOLOR$HN\W\$($gitps) \$$PROMPTRESET "
        PROMPT_COMMAND='echo -ne "\033]0;${HOSTNAME%%.*}:${PWD/$HOME/\~}\007";stty echo'
        ;;
    screen*)
        export PS1="$PROMPTCOLOR$HN\W\$($gitps) \$$PROMPTRESET "
        PROMPT_COMMAND='echo -ne "\033_${HOSTNAME%%.*}:${PWD/$HOME/\~}\033\\";stty echo'
        export TERM=screen-256color
        unset DISPLAY
        ;;
    tmux*)
        export PS1="$PROMPTCOLOR$HN\W\$($gitps) \$$PROMPTRESET "
        PROMPT_COMMAND='echo -ne "\033_${HOSTNAME%%.*}:${PWD/$HOME/\~}\033\\";stty echo'
        export TERM=tmux-256color
        unset DISPLAY
        ;;
    *)
        export PS1=$HN'\W$(__git_ps1) \$ '
esac

[ -f ~/.bashrc.d/$(uname -n) ] && source ~/.bashrc.d/$(uname -n)
[ -f ~/.less_termcap ] && source ~/.less_termcap
