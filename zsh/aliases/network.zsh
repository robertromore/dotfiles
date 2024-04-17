#!/bin/zsh

# Firewall management.
alias port-forward-enable="echo 'rdr pass inet proto tcp from any to any port 2376 -> 127.0.0.1 port 2376' | sudo pfctl -ef -"
alias port-forward-disable="sudo pfctl -F all -f /etc/pf.conf"
alias port-forward-list="sudo pfctl -s nat"

# IP address related commands.
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias iplocal="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Show active network interfaces.
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Show network connections.
# Often useful to prefix with SUDO to see more system level network usage
alias network.connections='lsof -l -i +L -R -V'
alias network.established='lsof -l -i +L -R -V | grep ESTABLISHED'
alias network.externalip='curl -s http://checkip.dyndns.org/ | sed "s/[a-zA-Z<>/ :]//g"'
alias network.internalip="ifconfig en0 | egrep -o '([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)'"

# DNS-related commands.
alias dnsflush='dscacheutil -flushcache'
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
