# -*- tab-width: 4; indent-tabs-mode: t; indent-style: tab; encoding: utf-8; -*-
umask 022
#limit coredumpsize 0

# if !interactive, exit
[[ $- =~ i ]] || exit

#
#	BASH settings
#
set -o emacs
set -o braceexpand
set -o noclobber
set +o errexit

# Correct dir spellings
shopt -q -s cdspell
# Make sure display get updated when terminal window get resized
shopt -q -s checkwinsize
# Turn on the extended pattern matching features 
shopt -q -s extglob
# Append rather than overwrite history on exit
shopt -s histappend
# Make multi-line commandsline in history
shopt -q -s cmdhist 
shopt -q -s lithist
# Get immediate notification of bacground job termination
set -o notify 
# Disable [CTRL-D] which is used to exit the shell
#set -o ignoreeof

PROMPT_COMMAND=()

set -a
[ -r ~/.environ ] && . ~/.environ
if [ -d ~/.cache ]; then
	HISTFILE=${HOME}/.cache/.bash_history
	HISTFILESIZE=2048
#	HISTSIZE=2048
fi
set +a
shopt -q -s mailwarn

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

### PROMPT

# colors
cblack="\033[30m"
cred="\033[1;31m"
cgreen="\033[1;32m"
cbrown="\033[1;33m"
cblue="\033[1;34m"
cmagenta="\033[1;35m"
ccyan="\033[1;36m"
cwhite="\033[1;37m"
creset="\033[0m"

# prompt selections
ctimecolor="$cmagenta"
cusercolor="$cgreen"
if [ $USERID -eq 0 ]; then
	cusercolor="$cred"
fi
chostcolor="$cgreen"
if [ -n "${REMOTEHOST-}" ]; then
	chostcolor="$cbrown"
fi
cdirxcolor="$cblue"
if [ $USERID -eq 0 ]; then
	cdirxcolor="$cred"
fi

PS1="\[$cusercolor\]\u\[$chostcolor\]@\h \[$cdirxcolor\]\w\[$creset\]"
export PS1=$PS1' \$ '

unset cblack cred cgreen cbrown cblue cmagenta ccyan cwhite
unset cusercolor chostcolor cdirxcolor

# find escape sequence to change terminal window title
case "$TERM" in
  (xterm|xterm[+-]*|gnome|gnome[+-]*|putty|putty[+-]*|cygwin)
    _tsl='\033];' _fsl='\a' ;;
  (*)
    _tsl=$( (tput tsl 0; echo) 2>/dev/null |
    sed -e 's;\\;\\\\;g' -e 's;;\\033;g' -e 's;;\\a;g' -e 's;%;%%;g')
    _fsl=$( (tput fsl  ; echo) 2>/dev/null |
    sed -e 's;\\;\\\\;g' -e 's;;\\033;g' -e 's;;\\a;g' -e 's;%;%%;g') ;;
esac

# if terminal window title can be changed...
if [ "$_tsl" ] && [ "$_fsl" ]; then

	# set terminal window title on each prompt
	_set_term_title() {
	if [ -t 2 ]; then
    	printf "$_tsl"'%s@%s:%s'"$_fsl" "${LOGNAME}" "${HOSTNAME%%.*}" \
	      "${${PWD:/$HOME/\~}/#$HOME\//\~\/}" >&2
	fi 
	}
	PROMPT_COMMAND=("$PROMPT_COMMAND" '_set_term_title')

	# reset window title when changing host or user
	ssh() {
		if [ -t 2 ]; then printf "$_tsl"'ssh %s'"$_fsl" "$*" >&2; fi
		command ssh "$@"
		}
	su() {
		if [ -t 2 ]; then printf "$_tsl"'su %s'"$_fsl" "$*" >&2; fi
		command su "$@"
		}
	sudo() {
		if [ -t 2 ]; then printf "$_tsl"'sudo %s'"$_fsl" "$*" >&2; fi
		command sudo "$@"
		}
fi

# print file type when executing non-executable files
_file_type() {
	if [ -e "$1" ] && ! [ -d "$1" ]; then
		file -- "$1"
	fi
}
COMMAND_NOT_FOUND_HANDLER=("$COMMAND_NOT_FOUND_HANDLER" '_file_type "$@"')

HISTCONTROL=‘ignoredups’

# aliases
[ -r ~/.aliases ] && . ~/.aliases
alias reload='. ~/.bashrc'
alias hist='history $(tput lines)'
alias dirs='dirs -v'

# another bug in the dust
#_cd() { pushd "$*" > /dev/null; }
#alias cd='_cd'

# pick
list="fzy pick"
pick_method="none"
for e in $list; do
	if [ -n "$(command -vp $e)" ]; then
		pick_method="$e"
		break
	fi
done
case $pick_method in
fzy)
	alias hc='x="$(fc -lnr | fzy)" && eval "$x"' 
	alias go='x=$(builtin dirs -v | fzy | cut -f1); [ -n "$x"] && cd +$x'
	alias cdd='x="$(ls -d1 */ --color=never | fzy)"; [ -n "$x" ] && cd "$x"'
	;;
pick)
	alias hc='x="$(fc -lnr | pick -S)" && eval "$x"'
	alias go='x=$(builtin dirs -v | pick -S | cut -f1); [ -n "$x" ] && cd +$x'
	alias cdd='x="$(ls -d1 */ --color=never | pick)"; [ -n "$x" ] && cd "$x"'  
	;;
esac

#	welcome screen
if shopt | grep '^login_shell.*on$' > /dev/null; then
	if [[ $TTY =~ tty* ]]; then
		/bin/echo -ne '\033='
	fi
	echo -e "Welcome to \033[1;36mBaSH\033[0m $BASH_VERSION"
	echo
	list=(diogenis neofetch screenfetch fortune)
	for e in ${list[@]}; do
		if which $e > /dev/null; then
			$e
			break
		fi
	done
fi
							
#	load local bashrc files
for e in ~/.bashrc-*; do
	[ -f $e ] && . $e
done

# clean up
unset _fsl _tsl e list
