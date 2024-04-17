#!/bin/zsh

alias rsync-copy="rsync -avz --progress -h"
alias rscp="rsync-cp"
alias rsync-move="rsync -avz --progress -h --remove-source-files"
alias rsmv="rsync-move"
alias rsync-update="rsync -avzu --progress -h"
alias rsup="rsync-update"
alias rsync-synchronize="rsync -avzu --delete --progress -h"
alias rssync="rsync-synchronize"
