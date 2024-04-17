#!/bin/zsh

alias fd='find . -type d -name'
alias ff='find . -type f -name'
# Usage: findstr "text" file/path/to/search
alias findstr="grep -iRl"
alias grep='grep --color'
alias hgrep="fc -El 0 | grep"
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '
