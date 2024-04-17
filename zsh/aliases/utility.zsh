#!/bin/zsh

# Lock the screen (when going AFK).
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

# Shortcut for `clear`.
alias c="clear"

# Recursively remove .DS_Store files.
alias cleanup="find . -name ".DS_Store" -depth -exec rm {} \;"

# Recursive dos2unix in current directory.
alias dos2lf='dos2unix `find ./ -type f`'

# Empty the Trash on all mounted volumes and the main HDD.
# Also, clear Apple’s System Logs to improve shell startup speed.
# Finally, clear download history from quarantine. https://mths.be/bum
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# Copy and paste and prune the usless newline
alias pbcopynn='tr -d "\n" | pbcopy'

alias reloadcli="source $HOME/.zshrc"

# Get macOS Software Updates, and update installed Ruby gems, Homebrew, npm, and their installed packages
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; mas upgrade; npm install npm -g; npm update -g; sudo gem update --system; sudo gem update; sudo gem cleanup'
