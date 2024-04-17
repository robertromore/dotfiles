#!/bin/zsh

# Directory listings
# LS_COLORS='no=01;37:fi=01;37:di=07;96:ln=01;36:pi=01;32:so=01;35:do=01;35:bd=01;33:cd=01;33:ex=01;31:mi=00;05;37:or=00;05;37:'
# -G Add colors to ls
# -l Long format
# -h Short size suffixes (B, K, M, G, P)
# -p Postpend slash to folders
alias lls='ls -G -h -p '
alias lll='ls -l -G -h -p '

if [[ -f  "$(brew --prefix coreutils)/libexec/gnubin/ls" ]]; then
  alias ll="$(brew --prefix coreutils)/libexec/gnubin/ls -ahlF --color --group-directories-first"
fi
