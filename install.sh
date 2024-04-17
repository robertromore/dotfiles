#!/bin/bash

# Dotfiles and bootstrap installer
# Installs git, clones repository and symlinks dotfiles to your home directory

set -e
trap on_error SIGKILL SIGTERM

count=1
numbers=(⓪ ① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩ ⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳ ㉑ ㉒ ㉓ ㉔ ㉕ ㉖ ㉗ ㉘ ㉙ ㉚ ㉛ ㉜ ㉝ ㉞ ㉟ ㊱ ㊲ ㊳ ㊴ ㊵ ㊶ ㊷ ㊸ ㊹ ㊺ ㊻ ㊼ ㊽ ㊾ ㊿)

# OS version detection
if  [[ -f "/etc/os-release" ]]; then
  (uname -a | grep -v 'Microsoft' >/dev/null) && OS_TYPE="Linux" || OS_TYPE="WSL"
  IFS=";" read OS_NAME OS_VERSION OS_ID OS_ID_LIKE < <(source "/etc/os-release"; echo "$NAME;$VERSION_ID;$ID;$ID_LIKE")
  export OS_TYPE OS_NAME OS_VERSION
elif (uname | grep 'Darwin' >/dev/null); then
  export OS_TYPE="Darwin"
  export OS_NAME="$(sw_vers -productName)"
  export OS_VERSION="$(sw_vers -productVersion)"
elif (uname | grep 'CYGWIN_NT' >/dev/null); then
  export OS_TYPE="Cygwin"
  export OS_NAME="Windows"
  export OS_VERSION="$(echo $(cmd /c ver) | sed 's/.*Version \(.*\)\..*]/\1/')"
fi

is_mac () {
  [[ "$OS_TYPE" == "Darwin" ]]
}

if [[ "$TERM" != "dumb" ]]; then
  # Console colors
  e='\033'
  red="${e}[0;91m"
  red_bg="${e}[101m"
  light_blue_bg="${e}[104m"
  yellow_bg="${e}[43m"
  lightmagenta_bg="${e}[0;105m"
  green="${e}[0;32m"
  green_bold="$bold$green"
  green_bg="${e}[42m"
  yellow="${e}[0;33m"
  yellow_bold="${e}[1;33m"
  blue="${e}[0;34m"
  lime="${e}[0;92m"
  acqua="${e}[0;96m"
  magenta="${e}[0;35m"
  magenta_bold="$bold$magenta"
  lightmagenta="${e}[0;95m"
  cyan="${e}[0;96m"
  highlight="${e}[41m${e}[97m"
  dim="${e}[2m"
  NC="${e}[0m"
  bold=$(tput bold)
  normal=$(tput sgr0)
  underline="\e[37;4m"
  black_text="${e}[38;5;232m"
  diamond=$'\xe2\x9c\xa6'
  upperleftjoin=$'\xe2\x94\x94'
  leftjoin=$'\xe2\x94\x9c'
  horizline=$'\xe2\x94\x80'
fi

WIDTH=$(tput cols)
HEIGHT=$(tput lines)

cursor_blink_on() {
  printf "$e[?25h";
}

cursor_blink_off() {
  printf "$e[?25l";
}

cursor_to() {
  printf "$e[$1;${2:-1}H";
}

get_cursor_row() {
  IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[};
}

_exists() {
  command -v $1 > /dev/null 2>&1
}

info() {
  _indent $1 info
  echo -e "${yellow}${@:2}${normal}"
}

success() {
  _indent $1 success
  echo -e "${green}${@:2}${normal}"
}

finish() {
  success 0 "${upperleftjoin}"$(echo-repeat "${horzline}" 75) "COMPLETE"
}

# print string in $1 for $2 times
echo-repeat() {
  for (( i=0; i<=$2; i++ )); do printf "%s" $1; done; echo ""
}

headline() {
    printf "${highlight} %s ${NC}\n" "$@"
}

chapter() {
  local fmt="$1"; shift
  local sep=$(echo-repeat ${horizline} $(($WIDTH / 2 + $WIDTH / 8)))
  printf "\n${red}${diamond}  ${normal}${bold}${count}. $fmt${normal}\n${leftjoin}${horizline}${horizline}${sep}${numbers[$((count++))]}\n" "$@"
}

# Prints out a step, if last parameter is true then without an ending newline
step() {
  _indent $1 step
  if [ $# -eq 2 ]
  then echo -e "${@:2}"
  else echo -ne "${@:2}"
  fi
}

run() {
  _indent $1 run
  cmd="${@:2}"
  for i in ${!cmd[@]}; do
    cmd[i]="${cmd[i]//\{\{CENSOR\}\}**\{\{\/CENSOR\}\}/****}"
  done
  echo -e "${cmd[@]} ${normal}";
  args=("${@:2}")
  $(echo "${args[@]}" | sed -e "s/{{CENSOR}}\(.*\){{\/CENSOR}}/\1/g")
}

runCmdArray() {
  _indent $1 run
  cmd=$2
  print="${cmd[@]//\{\{CENSOR\}\}**\{\{\/CENSOR\}\}/****}"
  for i in ${!cmd[@]}; do
    new_cmd[i]=$(echo ${cmd[i]} | sed -e "s/{{CENSOR}}\(..*\){{\/CENSOR}}/\1/g")
  done
  echo -e "${print[@]} ${normal}";
  ("${new_cmd[@]}")
}

runRedirectOutput() {
  _indent $1 run
  cmd="${@:2}"
  print="${cmd[@]//\{\{CENSOR\}\}**\{\{\/CENSOR\}\}/****}"
  echo -e "${print[@]} ${normal}";
  while read line; do
    info $1 $line
  done < <($(echo "${args[@]}" | sed -e "s/{{CENSOR}}\(.*\){{\/CENSOR}}/\1/g"))
}

runRedirectErr() {
  _indent $1 run
  cmd="${@:2}"
  print="${cmd[@]//\{\{CENSOR\}\}**\{\{\/CENSOR\}\}/****}"
  echo -e "${print[@]} ${normal}";
  args=("${@:2}")
  while read line; do
    info $1 $line
  done < <($(echo "${args[@]}" | sed -e "s/{{CENSOR}}\(.*\){{\/CENSOR}}/\1/g") > /dev/null 2>&1)
}

runRedirectAll() {
  _indent $1 run
  cmd="${@:2}"
  for i in ${!cmd[@]}; do
    cmd[i]="${cmd[i]//\{\{CENSOR\}\}**\{\{\/CENSOR\}\}/****}"
  done
  echo -e "${cmd[@]} ${normal}";
  args=("${@:2}")
  while read line; do
    info $1 $line
  done < <($(echo "${args[@]}" | sed -e "s/{{CENSOR}}\(.*\){{\/CENSOR}}/\1/g") 2>&1)
}

error() {
  echo -e "${normal}$(_indent $1 error)${red}${@:2}${normal}"
}

warn() {
  echo -e "${normal}$(_indent $1 warn)${yellow}${@:2}${normal}"
}

# @param level of indentation
_indent ()
{
  [[ $1 -eq 0 ]] && return

  arrow=$'\xe2\xae\x80'
  prefix="$cyan"
  spaces=$(( $1*2 ))

  if [[ $2 == 'step' ]]; then
    prefix="$yellow_bold"
    # arrow="▸"
    ((spaces+=3))
  elif [[ $2 == 'success' ]]; then
    prefix="$green_bold"
    # arrow="▸"
    # ((spaces+=3))
  elif [[ $2 == 'run' ]]; then
    prefix="$magenta_bold"
    # arrow="▹"
    ((spaces+=3))
  elif [[ $2 == 'info' ]] || [[ $2 == 'warn' ]]; then
    prefix="$yellow"
  elif [[ $2 == 'error' ]]; then
    prefix="$red"
  fi

  # if (($1 == 1)); then
    # indent="└"
  # else
    indent=$leftjoin
  # fi

  echo -en "$(echo -e $prefix)${indent}$(echo-repeat ${horizline} $spaces)${arrow} ${normal}"
}

# Prompt dialog with an optional message
# @param $1 indentation level
# @param $2 message
# @param $3 Y|N default answer
_prompt () {
  while true; do
    _indent $1
    echo -en "$2 "
    y="y"
    n="n"
    if [ "${3:-}" == "Y" ]; then
      y="$(echo -e $bold)Y$(echo -e $NC)"
    elif [ "${3:-}" == "N" ]; then
      n="$(echo -e $bold)N$(echo -e $NC)"
    fi

    read -p "[${y}/${n}]: " answer </dev/tty

    if [ -z "$answer" ]; then
      [[ "${3:-}" == "Y" ]] && return 0
      [[ "${3:-}" == "N" ]] && return 1
    fi

    case "$answer" in
      [Yy]|[Yy][Ee][Ss] )
        [[ "$4" == "--exit-on" && "$5" == "Y" ]] && exit 1
        return 0
        break
        ;;
      [Nn]|[Nn][Oo] )
        [[ "$4" == "--exit-on" && "$5" == "N" ]] && exit 1
        return 1
        ;;
      * )
        error $1 "Please answer yes or no."
    esac
  done
}

# Yes/no confirmation dialog with an optional message
# @param $1 indentation level
# @param $2 confirmation message
# @param $3 Y|N default answer
# @param $4 --exit-on
# @param $5 Y|N exits if this answer is provided
# @return 0 if no, 1 if yes
_confirm () {
  # echo ""
  _indent ${1:-0}
  echo -en "$2 "
  y="y"
  n="n"
  if [ "${3:-}" == "Y" ]; then
    y="$(echo -e $bold)Y$(echo -e $NC)"
  elif [ "${3:-}" == "N" ]; then
    n="$(echo -e $bold)N$(echo -e $NC)"
  fi
  echo -en "[${y}/${n}]: "

  while true; do
    case $(_select_key_input) in
      enter)
        echo
        [[ "${3:-}" == "Y" ]] && return 0
        [[ "${3:-}" == "N" ]] && return 1
        break
        ;;
      yes)
        echo
        return 0
        break
        ;;
      # esc)
      #   return 1
      #   break
      #   ;;
      no)
        echo
        return 1
        break
        ;;
    esac
  done
}

# Get user input and ensure answer is non-empty.
# @param $1 indententation level
# @param $2 input text
# @param $3 true to allow null values
_input () {
  input=

  while read -p "$(_indent $1)$2 $(echo -e $bold)" answer && [[ $3 = false ]] && [[ -z "$answer" ]]; do
    echo
    error $1 "Please provide a valid answer."
  done

  echo -en "${normal}"

  input="${answer[@]}"
}

# Similar to `_input` but the user's answer is not echoed.
# @param $1 indententation level
# @param $2 input text
# @param $3 true to allow null values
_silentinput () {
  input=

  while read -sp "$(_indent $1)$2 $(echo -e $bold)" answer && [ $3 = false ] && [[ -z "$answer" ]]; do
    echo
    error $1 "Please provide a valid answer."
  done

  echo -e "${normal}"

  input="${answer[@]}"
}

_select_key_input() {
  local key
  IFS= read -rsn1 key 2>/dev/null >&2
  if [[ $key = ""      ]]; then echo enter;
  elif [[ $key = "y"     ]]; then echo yes;
  elif [[ $key = "n"     ]]; then echo no;
  elif [[ $key = $'\x20' ]]; then echo space;
  # elif [[ $key = $'\e'   ]]; then echo esc;
  elif [[ $key = $'\x1b' ]]; then
    read -rsn2 key
    if [[ $key = [A ]];    then echo up;
    elif [[ $key = [B ]];    then echo down;
    elif [[ $key = [C ]];    then echo right;
    elif [[ $key = [D ]];    then echo left;  fi;
  fi
}

_select () {
  _indent ${1:-0}
  echo -e $3

  local size=$(stty size)
  local lines=${size% *}
  local columns=${size#* }
  # local columns="${$1:-$COLUMNS}"
  # local rows="${$2:-$ROWS}"
  local x=0
  local y=0

  print_inactive()
  {
    printf " $1 ";
  }

  print_active()
  {
    printf "$yellow_bg$black_text $1 $normal";
  }

  local retval="$2"
  local options
  local defaults=()
  local selected

  IFS=';' read -r -a options <<< "$4"
  if [[ -z $5 ]]; then
    defaults=()
  else
    IFS=';' read -r -a defaults <<< "$5"
  fi

  local maxy=$(( ${#options[@]} < $lines ? ${#options[@]} : $lines - 2 ))
  for ((i=0; i<maxy; i++)); do
    [[ "${defaults[$i]}" ]] && selected="$i"
    printf "\n"
  done

  # determine current screen position for overwriting the options
  local lastrow=`get_cursor_row`
  local startrow=$(($lastrow - $maxy))

  # ensure cursor and input echoing back on upon a ctrl+c during read -s
  trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
  cursor_blink_off

  local active="$selected"
  while true; do
    # print options by overwriting the last lines
    local idy="$y"
    local liney=0
    for option in "${options[@]:$idy:$maxy}"; do
      local prefix="[ ]"
      if [[ ${selected[idy]} == true ]]; then
        prefix="[x]"
      fi

      cursor_to $(($startrow + $liney))
      if [ $idy -eq $active ]; then
        print_active "$option"
      else
        print_inactive "$option"
      fi
      ((++idy)) && ((++liney))
    done

    # user key control
    case $(_select_key_input) in
      enter)  break;;
      up)     ((active--));
              if [ $active -lt 0 ]; then
                active=$((${#options[@]} - 1))
                y=$((${#options[@]} - $maxy))
              elif [ $active -lt $y ]; then
                ((--y))
              fi;;
      down)   ((active++));
              if [ $active -ge ${#options[@]} ]; then
                active=0
                y=0
              elif [ $active -ge $(($y + $maxy)) ]; then
                ((++y))
              fi;;
    esac
  done

  # cursor position back to normal
  cursor_to $lastrow
  # printf "\n"
  cursor_blink_on

  eval $retval='("${options[${active}]}")'
}

_multiselect () {
  local columns="${$1:-COLUMNS}"
  local rows="${$2:-ROWS}"
  local x=0
  local y=0

  print_inactive()
  {
    printf "$2   $1 ";
  }

  print_active()
  {
    printf "$2  $e[7m $1 $e[27m";
  }

  key_input()
  {
    local key
    IFS= read -rsn1 key 2>/dev/null >&2
    if [[ $key = ""      ]]; then echo enter; fi;
    if [[ $key = $'\x20' ]]; then echo space; fi;
    if [[ $key = $'\x1b' ]]; then
      read -rsn2 key
      if [[ $key = [A ]]; then echo up;    fi;
      if [[ $key = [B ]]; then echo down;  fi;
      if [[ $key = [C ]]; then echo right; fi;
      if [[ $key = [D ]]; then echo left; fi;
    fi
  }

  toggle_option()
  {
    local arr_name="$1"
    eval "local arr=(\"\${${arr_name}[@]}\")"
    local option="$2"
    if [[ ${arr[option]} == true ]]; then
      arr[option]=
    else
      arr[option]=true
    fi
    eval $arr_name='("${arr[@]}")'
  }

  local retval="$1"
  local options
  local defaults

  IFS=';' read -r -a options <<< "$2"
  if [[ -z $3 ]]; then
    defaults=()
  else
    IFS=';' read -r -a defaults <<< "$3"
  fi
  local selected=()

  local maxy=$(( ${#options[@]} < $lines ? ${#options[@]} : $lines - 2 ))
  for ((i=0; i<maxy; i++)); do
    selected+=("${defaults[i]}")
    printf "\n"
  done

  # determine current screen position for overwriting the options
  local lastrow=`get_cursor_row`
  local startrow=$(($lastrow - $maxy))

  # ensure cursor and input echoing back on upon a ctrl+c during read -s
  trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
  cursor_blink_off

  local active=0
  local y=0
  while true; do
    # print options by overwriting the last lines
    local idy="$y"
    local liney=0
    for option in "${options[@]:$idy:$maxy}"; do
      local prefix="[ ]"
      if [[ ${selected[idy]} == true ]]; then
        prefix="[x]"
      fi

      cursor_to $(($startrow + $liney))
      if [ $idy -eq $active ]; then
        print_active "$option" "$prefix"
      else
        print_inactive "$option" "$prefix"
      fi
      ((++idy)) && ((++liney))
    done

    # user key control
    case `key_input` in
      space)  toggle_option selected $active;;
      enter)  break;;
      up)     ((active--));
              if [ $active -lt 0 ]; then
                active=$((${#options[@]} - 1))
                y=$((${#options[@]} - $maxy))
              elif [ $active -lt $y ]; then
                ((--y))
              fi;;
      down)   ((active++));
              if [ $active -ge ${#options[@]} ]; then
                active=0
                y=0
              elif [ $active -ge $(($y + $maxy)) ]; then
                ((++y))
              fi;;
    esac
  done

  # cursor position back to normal
  cursor_to $lastrow
  printf "\n"
  cursor_blink_on

  eval $retval='("${selected[@]}")'
}

# @param indentation level
# @param custom message
_waitforenter() {
  msg=$2
  if [[ -z msg ]]; then
    msg="Press [ENTER] to continue."
  fi

  info $1 $msg

  while true; do
    IFS= read -rsn1 key 2>/dev/null >&2
    if [[ $key = "" ]]; then
      return 0
    fi
  done
}

on_start() {
  echo
  echo -e "${red}${bold} / / /\ \ \___| |__ ${NC}${bold} ___ _ __   ___  ___ ${NC}"
  echo -e "${red}${bold} \ \/  \/ / _ | '_ "'\\'"${NC}${bold}/ __| '_ \ / _ \/ __|${NC}"
  echo -e "${red}${bold}  \  /\  |  __| |_) ${NC}${bold}\__ | |_) |  __| (__ ${NC}"
  echo -e "${red}${bold}   \/  \/ \___|_.__/${NC}${bold}|___| .__/ \___|\___|${NC}"
  echo -e "${red}${bold}                    ${NC}${bold}    |_|              ${NC}"
  echo -e "   ${yellow_bg}${black_text}${bold} State Team ${NC}"

  info 0 "This script will help you setup and maintain your development environment."

  # Ask for the administrator password upfront
  if [[ $(sudo -n uptime 2>&1|grep "load"|wc -l) -eq 0 ]]; then
    RUN_AS_ROOT=false
    if _confirm 0 "Some steps will not appear unless we are granted administrative privileges. Do you want to provide that now?" "Y"; then
      step 0
      sudo -v
      echo ""
      RUN_AS_ROOT=true
    fi
  else
    RUN_AS_ROOT=true
  fi
}

setup_system() {
  chapter "General Settings"

  if [[ is_mac ]]; then
    # Close any open System Preferences panes, to prevent them from overriding
    # settings we’re about to change
    osascript -e 'tell application "System Preferences" to quit'

    if _confirm 1 "Configure general system settings?" "Y"; then
      if $RUN_AS_ROOT && _confirm 2 "Set system name?" "N"; then
        _input 3 "What would you like your system name to be? $bold"
        run 3 sudo scutil --set ComputerName "'$computer_name'"
        run 3 sudo scutil --set HostName "'$computer_name'"
        run 3 sudo scutil --set LocalHostName "'$computer_name'"
        run 3 sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "'$computer_name'"
      fi

      local interval=
      if _confirm 2 "Configure update interval?" "N"; then
        _select 3 interval "How often would you like to check for updates?" "Never;Daily;Weekly;Fortnightly;Monthly" ";true;;;"
        [[ $interval == 'Never' ]] && run 3 defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 0
        [[ $interval == 'Daily' ]] && run 3 defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
        [[ $interval == 'Weekly' ]] && run 3 defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 7
        [[ $interval == 'Fortnightly' ]] && run 3 defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 14
        [[ $interval == 'Monthly' ]] && run 3 defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 30
      fi

      if $RUN_AS_ROOT && _confirm 2 "Disable sound effects?" "Y"; then
        run 2 sudo nvram SystemAudioVolume=" "
      fi

      if $RUN_AS_ROOT && _confirm 2 "Reveal IP address, hostname, OS version, etc. when clicking the login window clock?" "Y"; then
        run 2 sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
      fi

      if _confirm 2 "Disable automatic termination of inactive apps?" "Y"; then
        run 2 defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
      fi

      if _confirm 2 "Disable the 'Are you sure you want to open this application?' dialog?" "Y"; then
        run 2 defaults write com.apple.LaunchServices LSQuarantine -bool false
      fi

      if _confirm 2 "Increase window resize speed for Cocoa applications?" "Y"; then
        run 2 defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
      fi

      if _confirm 2 "Disable window resume system-wide?" "Y"; then
        run 2 defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
      fi

      if $RUN_AS_ROOT && _confirm 2 "Automatically restart if system freezes?" "Y"; then
        run 2 sudo systemsetup -setrestartfreeze on
      fi

      if _confirm 2 "Maximize windows when double-clicking their title bar?" "Y"; then
        run 2 defaults write -g AppleActionOnDoubleClick 'Maximize'
      fi
    fi

    if _confirm 1 "Configure SSD settings (only if you have an SSD)?" "N"; then
      if $RUN_AS_ROOT && _confirm 1 "Disable local Time Machine snapshots?" "Y"; then
        run 1 "sudo tmutil disablelocal"
      fi

      if $RUN_AS_ROOT && _confirm 1 "Disable hibernation (speeds up entering sleep mode)?" "Y"; then
        run 1 "sudo pmset -a hibernatemode 0"
      fi

      if $RUN_AS_ROOT && _confirm 1 "Remove the sleep image file to save disk space?" "Y"; then
        run 1 "sudo rm /Private/var/vm/sleepimage"
        # Create a zero-byte file instead...
        run 1 "sudo touch /Private/var/vm/sleepimage"
        # ...and make sure it can’t be rewritten
        run 1 "sudo chflags uchg /Private/var/vm/sleepimage"
      fi

      if $RUN_AS_ROOT && _confirm 1 "Disable the sudden motion sensor (as it’s not useful for SSDs)?" "Y"; then
        run 1 "sudo 1 pmset -a sms 0"
      fi
    fi

    if _confirm 1 "Configure input (trackpad, mouse, keyboard, Bluetooth accessories, etc.)?" "N"; then
      if _confirm 2 "Enable tap to click?" "Y"; then
        run 2 "defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1"
        run 2 "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1"
      fi

      if _confirm 2 "Enable right click (tap with two fingers)?" "Y"; then
        run 2 "defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -int 1"
        run 2 "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -int 1"
      fi

      if _confirm 2 "Enable application change (swipe horizontal witch three fingers)?" "Y"; then
        run 2 "defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2"
        run 2 "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 2"
      fi

      if _confirm 2 "Enable the Launchpad gesture (pinch with thumb and three fingers)?"; then
        run 2 "defaults write com.apple.dock showLaunchpadGestureEnabled -int 1"
      fi

      if _confirm 2 "Enable Expose gesture (slide down with three fingers)?"; then
        run 2 "defaults write com.apple.dock showAppExposeGestureEnabled -int 1"
      fi

      if _confirm 2 "Map bottom right corner of trackpad to right-click?" "N"; then
        run 2 "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2"
        run 2 "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true"
        run 2 "defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1"
        run 2 "defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true"
      fi

      if _confirm 2 "Disable auto-correct?" "Y"; then
        run 2 "defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false"
        run 2 "defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -int 0"
      fi

      if _confirm 2 "Disable automatic capitalization" "N"; then
        run 2 "defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false"
      fi

      if _confirm 2 "Disable smart quotes (not useful when writing code)?" "Y"; then
        run 2 "defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false"
      fi

      if _confirm 2 "Disable smart dashes (not useful when writing code)?" "Y"; then
        run 2 "defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false"
      fi

      if _confirm 2 "Disable automatic period substitution?" "Y"; then
        run 2 "defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false"
      fi

      if _confirm 2 "Use scroll gesture with the Ctrl (^) modifier key to zoom?" "Y"; then
        run 2 "defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true"
        run 2 "defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144"
      fi

      if _confirm 2 "Follow the keyboard focus while zoomed in?" "Y"; then
        run 2 "defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true"
      fi

      if _confirm 2 "Disable press-and-hold for keys in favor of key repeat?" "Y"; then
        run "defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false"
        # Set a blazingly fast keyboard repeat rate, and make it happen more quickly.
        run 2 "defaults write NSGlobalDomain InitialKeyRepeat -int 20"
        run 2 "defaults write NSGlobalDomain KeyRepeat -int 1"
      fi

      if _confirm 2 "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)?" "Y"; then
        run 2 "defaults write NSGlobalDomain AppleKeyboardUIMode -int 3"
      fi

      if _confirm 2 "Increase sound quality for Bluetooth headphones/headsets?" "Y"; then
        run 2 "defaults write com.apple.BluetoothAudioAgent \"Apple Bitpool Min (editable)\" -int 40"
      fi
    fi

    if _confirm 1 "Configure screen settings?" "N"; then
      if _confirm 2 "Require password immediately after sleep or screen saver begins" "N"; then
        run 2 defaults write com.apple.screensaver askForPassword -int 1
        run 2 defaults write com.apple.screensaver askForPasswordDelay -int 0
      fi

      if _confirm 2 "Enable subpixel font rendering on non-Apple LCDs" "Y"; then
        run 2 defaults write NSGlobalDomain AppleFontSmoothing -int 2
      fi

      if $RUN_AS_ROOT && _confirm 2 "Enable HiDPI display modes? (requires restart)"; then
        run 2 sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
      fi
    fi

    if _confirm 1 "Configure screenshot settings?" "N"; then
      if _confirm 2 "Save screenshots to the desktop" "Y"; then
        run 2 defaults write com.apple.screencapture location -string "${HOME}/Desktop"
      fi

      if _confirm 2 "Save screenshots in PNG format?" "Y"; then
        run 2 defaults write com.apple.screencapture type -string "png"
      fi

      if _confirm 2 "Disable shadow in screenshots" "Y"; then
        run 2 defaults write com.apple.screencapture disable-shadow -bool true
      fi
    fi

    if _confirm 1 "Configure Finder settings?" "Y"; then
      if _confirm 2 "Open the 'home' directory by default when opening a new finder window?" "Y"; then
        run 2 defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
      fi

      if _confirm 2 "Show hidden files by default?" "Y"; then
        run 2 defaults write com.apple.finder AppleShowAllFiles -bool true
      fi

      if _confirm 2 "Show all filename extensions?" "Y"; then
        run 2 defaults write NSGlobalDomain AppleShowAllExtensions -bool true
      fi

      if _confirm 2 "Disable the warning when changing a file extension?" "Y"; then
        run 2 defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
      fi

      if _confirm 2 "Avoid creating .DS_Store files on network volumes?" "Y"; then
        run 2 defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
      fi

      if _confirm 2 "Display the status bar?" "Y"; then
        run 2 defaults write com.apple.finder ShowStatusBar -bool true
      fi

      if _confirm 2 "Display the path bar?" "Y"; then
        run 2 defaults write com.apple.finder ShowPathbar -bool true
      fi

      if _confirm 2 "Allow text selection in Quick Look?" "Y"; then
        run 2 defaults write com.apple.finder QLEnableTextSelection -bool true
      fi

      if _confirm 2 "Display full POSIX path as Finder window title?" "Y"; then
        run 2 defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
      fi

      if _confirm 2 "When searching, search the current folder by default?" "Y"; then
        run 2 defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
      fi

      if _confirm 2 "Keep folders on top when sorting by name?" "Y"; then
        run 2 defaults write com.apple.finder _FXSortFoldersFirst -bool true
      fi

      if _confirm 2 "Disable tags?" "N"; then
        run 2 defaults write com.apple.finder ShowRecentTags -int 0
      fi

      if _confirm 2 "Expand the save panel by default?" "Y"; then
        run 2 defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
        run 2 defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
      fi

      if _confirm 2 "Expand the print panel by default?" "Y"; then
        run 2 defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
      fi

      if _confirm 2 "Save to disk (not to iCloud) by default?" "Y"; then
        run 2 defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
      fi

      if _confirm 2 "Show icons for hard drives on the desktop?" "Y"; then
        run 2 defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
        run 2 defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
      fi

      if _confirm 2 "Show icons for servers on the desktop?" "Y"; then
        run 2 defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
      fi

      if _confirm 2 "Show icons for removable media on the desktop?" "Y"; then
        run 2 defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
      fi

      if _confirm 2 "Disable the warning before emptying the Trash?" "Y"; then
        run 2 defaults write com.apple.finder WarnOnEmptyTrash -bool false
      fi

      if _confirm 2 "Show the ~/Library folder?" "Y"; then
        run 2 chflags nohidden ~/Library
      fi

      if _confirm 2 "Expand the 'General' file info pane by default?" "Y"; then
        run 2 defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true
      fi

      if _confirm 2 "Expand the 'Open with' file info pane by default?" "Y"; then
        run 2 defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true
      fi

      if _confirm 2 "Expand the 'Preview' file info pane by default?" "Y"; then
        run 2 defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true
      fi

      if _confirm 2 "Expand the 'Sharing & Permissions' file info pane by default?" "Y"; then
        run 2 defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true
      fi
    fi

    if _confirm 1 "Configure Safari settings?" "Y"; then
      if _confirm 2 "Set Safari’s home page to \`about:blank\` for faster loading?" "Y"; then
        run 3 defaults write com.apple.Safari HomePage -string "about:blank"
      fi

      if _confirm 2 "Prevent Safari from opening ‘safe’ files automatically after downloading?" "Y"; then
        run 3 defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
      fi

      if _confirm 2 "Disable Safari’s thumbnail cache for History and Top Sites?" "Y"; then
        run 3 defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2
      fi

      if _confirm 2 "Enable Safari’s debug menu?" "Y"; then
        run 3 defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
      fi

      if _confirm 2 "Enable the Develop menu and the Web Inspector in Safari?" "Y"; then
        run 3 defaults write com.apple.Safari IncludeDevelopMenu -bool true
        run 3 defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
        run 3 defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
      fi

      if _confirm 2 "Add a context menu item for showing the Web Inspector in web views?" "Y"; then
        run 3 defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
      fi

      if _confirm 2 "Prevent Safari from sending search queries to Apple? (enhanced privacy)" "Y"; then
        run 3 defaults write com.apple.Safari UniversalSearchEnabled -bool false
        run 3 defaults write com.apple.Safari SuppressSearchSuggestions -bool true
      fi
    fi

    # This doesn't work on 10.12+ if SIP is enabled.
    # if $RUN_AS_ROOT && _confirm 1 "Configure Spotlight settings?" "Y"; then
    #   if _confirm 2 "Disable Spotlight indexing for any volume that gets mounted and has not yet been indexed before?" "Y"; then
    #     run 3 "sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array \"/Volumes\""
    #     # Restart spotlight
    #     run 3 "killall mds > /dev/null 2>&1"
    #   fi
    # fi
  fi

  finish
}

_install_xcode() {
  info $1 "Installing Command Line Tools..."

  xcode-select --install > /dev/null 2>&1

  _waitforenter $1 "A dialog will appear prompting you to agree to the terms and conditions. Once you've finished, press [ENTER] to continue."

  # Wait until the XCode Command Line Tools are installed
  until xcode-select --print-path &> /dev/null; do
    sleep 5
  done

  sudo xcodebuild -license accept
}

install_cli_tools() {
  chapter "CLI Tools"

  if [ is_mac ]; then
    info 1 "Trying to detect installed Command Line Tools...";

    if ! xcode-select --print-path &> /dev/null; then
      info 1 "You don't have Command Line Tools installed!";
      if _confirm 1 "Do you want me to try installing it for you?"; then
        _install_xcode 2;
      fi
    else
      success 1 "Seems like you have Command Line Tools installed. Skipping...";
    fi
  fi

  finish
}

HOMEBREW_INSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
install_homebrew() {
  if ! is_mac; then
    return
  fi

  chapter "Homebrew"

  info 1 "Looking for Homebrew..."

  if ! _exists brew; then
    info 1 "Couldn't find Homebrew."
    if _confirm 1 "Do you want me to try installing it for you?"; then
      info 2 "Installing Homebrew..."
      HOMEBREW_INSTALL_SCRIPT="$(curl -fsSL $HOMEBREW_INSTALLER_URL)"
      /bin/bash -c $HOMEBREW_INSTALL_SCRIPT 2>&1
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.profile
      eval "$(/opt/homebrew/bin/brew shellenv)"
      run 2 brew update
      run 2 brew upgrade
      run 2 brew cleanup
    fi
  else
    success 1 "You already have Homebrew installed. Skipping..."
  fi

  finish
}

_check_homebrew() {
  info 1 "Checking Homebrew installation"

  if [[ $(brew doctor 2>&1) == *"Warning: Xcode alone is not sufficient"* ]]; then
    _install_xcode 2
  fi
}

_remove_homebrew_packages() {
  brew list -1 | xargs brew rm
  brew cask list -1 | xargs brew cask rm
}

_homebrew_prompts() {
  if _confirm $1 "I've installed the Brew package coreutils, which provides various GNU utilities. macOS already comes with some of these, so Brew has prefixed these conflicting programs with 'g'. Would you like me to configure your environment to use their normal names instead?" "N"; then
    echo 'export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"' >> "$HOME/.zshenv.local"
  fi

  if _confirm $1 "I've installed GNU's \`sed\`, but since macOS already comes with an older version of \`sed\` this newer package has been renamed to \`gsed\`. Would you like me to configure your environment to use the newer version of GNU's \`sed\` by default?" "N"; then
    echo 'export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"' >> "$HOME/.zshenv.local"
  fi

  if _confirm $1 "I've installed GNU's various find utilities. macOS already comes with these commands, so Brew has prefixed the conflicting programs with 'g'. Would you like me to configure your environment to use their normal names instead?" "N"; then
    echo 'export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"' >> "$HOME/.zshenv.local"
  fi

  if _confirm $1 "I've installed GNU's \`grep\` utility. macOS already comes with an older version, so Brew has prefixed the conflicting program with 'g'. Would you like me to configure your environment to use its normal name instead?" "N"; then
    echo 'export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"' >> "$HOME/.zshenv.local"
  fi

  if _confirm $1 "I've installed NVM for you, which installs and manages different versions of Node. Would you like me to configure your environment for NVM?" "Y"; then
    if [[ ! -e "$HOME/.nvm" ]]; then
      mkdir "$HOME/.nvm"
    fi

    echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.zshenv.local" >> "$HOME/.zshenv.local"
    echo '[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm' >> "$HOME/.zshenv.local"
    echo '[ -s "/usr/local/opt/nvm/etc/bash_completion" ] && . "/usr/local/opt/nvm/etc/bash_completion"  # This loads nvm bash_completion' >> "$HOME/.zshenv.local"
  fi

  if _confirm $1 "I've installed an updated version of Bash. Would you like me to add it to your shells file?" "Y"; then
    echo "$(command -v bash)" | sudo tee -a /etc/shells
    chsh -s "$(command -v bash)" || error 1 "Error: Cannot set Bash as default shell!"
  fi

  if _confirm $1 "I've installed zshell for you, would you like me to add it to your shells file?" "Y"; then
    echo "$(command -v zsh)" | sudo tee -a /etc/shells
    chsh -s "$(command -v zsh)" || error 1 "Error: Cannot set Zsh as default shell!"
  fi
}

update_homebrew() {
  chapter "Homebrew: Update"

  _check_homebrew
  if _confirm 1 "Would you like to update your Homebrew packages?" "Y"; then
    runRedirectAll 2 "brew bundle install --file=$HOME/dotfiles/homebrew/Brewfile"
    run 2 brew update
    run 2 brew upgrade

    if [[ -e "$HOME/.Brewfile" ]]; then
      run 2 brew bundle --global
    fi

    run 2 brew cleanup
  fi

  if _confirm 1 "Run through Homebrew configuration prompts?" "Y"; then
    _homebrew_prompts 2
  fi

  finish
}

ghkeyfile=
ghemail=
_gh_create_keyfile() {
  _input $1 "What email would you like to use for the keyfile? (defaults to your global user email)" true
  ghemail=$input
  if [[ -z $ghemail ]]; then
    ghemail=$(git config --global --get user.email)
  fi

  while true; do
    _input $1 "What path would you like to use for the keyfile? (defaults to \"~/.ssh/id_gh\")" true

    if [[ -z $input ]]; then
      input="$HOME/.ssh/id_gh"
    fi

    if [[ ! -e $input ]]; then
      break
    fi

    warn $(($1+1)) "That keypath already exists"
    if _confirm $(($1+1)) "Do you want to overwrite it?" "N"; then
      break
    fi
  done

  ghkeyfile=$input

  _silentinput $1 "What password would you like to use for the keyfile? (press ENTER for no password)" true
  ghkeypass=$input

  declare -ap cmd=(ssh-keygen -q -t rsa -b 4096 -C "$ghemail" -f "$ghkeyfile" -N "{{CENSOR}}$ghkeypass{{/CENSOR}}") > /dev/null
  runCmdArray $1 $cmd
  _waitforenter $1 "A new SSH key has been generated for GitHub and the public key has been copied to your clipboard. Press [ENTER] to open a new browser window to your GitHub account's \"New SSH key\" page (https://github.com/settings/ssh/new), and paste your new key in the \"Key\" field. Come back once you're done."

  pbcopy < $ghkeyfile.pub
  open "https://github.com/settings/ssh/new"

  _waitforenter $1 "Press [ENTER] once you've saved the key to GitHub."

  if _confirm $1 "Would you like me to add this configuration to your SSH config file?" "Y"; then
    echo "Host github.com" >> $HOME/.ssh/config
    echo "  HostName github.com" >> $HOME/.ssh/config
    echo "  IdentityFile $ghkeyfile" >> $HOME/.ssh/config
    echo "  User git" >> $HOME/.ssh/config
    echo "  Preferredauthentications publickey" >> $HOME/.ssh/config
  fi
}

glkeyfile=
glemail=
_gl_create_keyfile() {
  _input $1 "What email would you like to use for the keyfile? (defaults to your global user email)" true
  glemail=$input
  if [[ -z $glemail ]]; then
    glemail=$(git config --global --get user.email)
  fi

  while true; do
    _input $1 "What path would you like to use for the keyfile? (defaults to \"~/.ssh/id_gl\")" true

    if [[ -z $input ]]; then
      input="$HOME/.ssh/id_gl"
    fi

    if [[ ! -e $input ]]; then
      break
    fi

    warn $(($1+1)) "That keypath already exists"
    if _confirm $(($1+1)) "Do you want to overwrite it?" "N"; then
      break
    fi
  done

  glkeyfile=$input

  _silentinput $1 "What password would you like to use for the keyfile? (press ENTER for no password)" true
  glkeypass=$input

  declare -ap cmd=(ssh-keygen -q -t rsa -b 4096 -C "$glemail" -f "$glkeyfile" -N "{{CENSOR}}$glkeypass{{/CENSOR}}") > /dev/null
  runCmdArray $1 $cmd
  _waitforenter $1 "A new SSH key has been generated for GitLab and the public key has been copied to your clipboard. Press [ENTER] to open a new browser window to your GitLab account's \"New SSH key\" page (https://gitlab.com/-/user_settings/ssh_keys), and paste your new key in the \"Key\" field. Come back once you're done."

  pbcopy < $glkeyfile.pub
  open "https://gitlab.com/-/user_settings/ssh_keys"

  _waitforenter $1 "Press [ENTER] once you've saved the key to GitLab."

  if _confirm $1 "Would you like me to add this configuration to your SSH config file?" "Y"; then
    echo "Host gitlab.com" >> $HOME/.ssh/config
    echo "  HostName gitlab.com" >> $HOME/.ssh/config
    echo "  IdentityFile $glkeyfile" >> $HOME/.ssh/config
    echo "  User git" >> $HOME/.ssh/config
    echo "  Preferredauthentications publickey" >> $HOME/.ssh/config
  fi
}

install_git() {
  chapter "Git"

  if _confirm 1 "Would you like to setup Git?" "Y"; then
    # Should be installed with brew, but just in case.
    if ! _exists git; then
      info 1 "Seems like you don't have Git installed!"
      if _confirm 1 "Do you want me to install it for you?"; then
        info 2 "Installing Git..."

        if is_mac; then
          run 2 brew install git
        elif is_debian; then
          run 2 sudo apt-get install git
        else
          error 2 "Error: Failed to install Git!"
          exit 1
        fi
      fi
    else
      success 1 "You already have Git installed. Skipping..."
    fi

    if _confirm 1 "Would you like to configure your global git user settings?" "N"; then
      _input 2 "What name would you like to use for Git? $(echo -e $dim)(E.g. \"John Smith\")$(echo -e $NC)"
      declare -ap cmd=(git config --global user.name "\"$input\"") > /dev/null
      runCmdArray 2 $cmd

      _input 2 "What email would you like to use for Git? $(echo -e $dim)(E.g. \"johnsmith@google.com\")$(echo -e $NC)"
      declare -ap cmd=(git config --global user.email "\"$input\"") > /dev/null
      runCmdArray 2 $cmd
    fi

    if _confirm 1 "Do you have a GitHub account? It will be needed for some of the proceeding steps." "Y"; then
      if _confirm 2 "Do you already have an SSH key for GitHub set up on this computer?" "N"; then
        _input 3 "What is the path to your keyfile? (press [ENTER] if using ~/.ssh/id_gh)"
        ghkeyfile=$input
        if [[ -z $ghkeyfile ]]; then
          ghkeyfile="$HOME/.ssh/id_gh"
        fi
        ghexists=true
      else
        if _confirm 3 "Would you like me to set one up for you?" "Y"; then
          _gh_create_keyfile 4
          ghexists=true
        fi
      fi
    else
      if _confirm 1 "Would you like to create one now? If not, I will skip the steps requiring GitHub." "Y"; then
        _waitforenter 2 "Click [ENTER] to open a new browser window to the GitHub account creation page."
        open "https://github.com/join"

        _waitforenter 2 "Once you've created your account, press [ENTER] to continue."
        _gh_create_keyfile 2

        ghexists=true
      else
        ghexists=false
      fi
    fi

    if [ $ghexists = true ] && _confirm 1 "Do you want to add your GitHub SSH key to your keyring? (recommended)" "Y"; then
      eval $(ssh-agent) > /dev/null 2>&1
      runRedirectErr 2 "ssh-add -K $ghkeyfile"
    fi

    if _confirm 1 "Do you have a GitLab account?" "Y"; then
      if _confirm 2 "Do you already have an SSH key for GitLab set up on this computer?" "N"; then
        _input 3 "What is the path to your keyfile? (press [ENTER] if using ~/.ssh/id_gl)"
        glkeyfile=$input
        if [[ -z $glkeyfile ]]; then
          glkeyfile="$HOME/.ssh/id_gl"
        fi
        glexists=true
      else
        if _confirm 3 "Would you like me to set one up for you?" "Y"; then
          _gl_create_keyfile 4
          glexists=true
        fi
      fi
    else
      if _confirm 1 "Would you like to create one now?" "Y"; then
        _waitforenter 2 "Click [ENTER] to open a new browser window to the GitLab account creation page."
        open "https://gitlab.com/users/sign_in#register-pane"

        _waitforenter 2 "Once you've created your account, press [ENTER] to continue."
        _gl_create_keyfile 2

        glexists=true
      else
        glexists=false
      fi
    fi

    if [ $glexists = true ] && _confirm 1 "Do you want to add your GitLab SSH key to your keyring? (recommended)" "Y"; then
      eval $(ssh-agent) > /dev/null 2>&1
      runRedirectErr 2 "ssh-add -K $glkeyfile"
    fi
  fi

  finish
}

install_zsh() {
  chapter "ZSH"

  info 1 "Looking for Zsh..."

  # Should be installed with brew, but just in case.
  if ! _exists zsh; then
    info 1 "Seems like you don't have Zsh installed!"
    if _confirm 1 "Do you want me to install it for you?" "Y"; then
      info 2 "Installing ZSH..."

      if is_mac; then
        run 2 brew install zsh zsh-completions
      elif is_debian; then
        run 2 sudo apt-get install zsh
      else
        error 2 "Error: Failed to install Zsh!"
        exit 1
      fi
    fi
  else
    success 1 "You already have Zsh installed. Skipping..."
  fi

  if $RUN_AS_ROOT && _exists zsh && [[ ${SHELL:-3:3} != "/bin/zsh" ]]; then
    _confirm 1 "Do you want me to set ZSH as your default shell?" "Y"

    echo "$(command -v zsh)" | sudo tee -a /etc/shells
    chsh -s "$(command -v zsh)" || error 1 "Error: Cannot set Zsh as default shell!"
  fi

  finish
}

install_misc() {
  chapter "Misc"

  if [[ ! -e $HOME/.nanorc ]] && _confirm 1 "Want me to install the Improved Nano Syntax Highlighting Files project? (improves syntax highlighting for numerous languages in nano) [https://github.com/scopatz/nanorc]" "Y"; then
    curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh >/dev/null
  else
    info 1 "No tasks available."
  fi

  finish
}

_dotbot_install() {
  CONFIG="install.conf.yaml"
  DOTBOT_DIR="dotbot"

  DOTBOT_BIN="bin/dotbot"
  BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  cd "${BASEDIR}"
  git submodule update --init --recursive "${DOTBOT_DIR}"

  "${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" -c "${CONFIG}" "${@}"
}

DOTFILES="$HOME/.dotfiles"
DOTFILES_REPO_URL="git@github.com:robertromore/dotfiles.git"
install_dotfiles() {
  chapter "Dotfiles"

  info 1 "Looking for dotfiles in $DOTFILES..."

  if [ ! -d $DOTFILES ]; then
    if _confirm 1 "I couldn't find my dotfiles. Do you want to download and link them?" "Y"; then
      git clone --recursive "$DOTFILES_REPO_URL" $DOTFILES
      info "Linking dotfiles..."
      cd $DOTFILES && _dotbot_install && cd -
    fi
  else
    if _confirm 1 "Found my dotfiles! Do you want to update them?" "Y"; then
      info "Linking dotfiles..."
      cd $DOTFILES && git pull && _dotbot_install && cd -
    fi
  fi

  finish
}

update_vscode_settings() {
  chapter "VSCode Settings"

  if _confirm 1 "Copy/overwrite vscode settings with ours?" "Y"; then
    cp -f "./vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    cp -f "./vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  fi

  if _confirm 1 "Install our vscode extensions?" "Y"; then
    source ./vscode/install.sh
  fi

  finish
}

on_finish() {
  killall Finder

  echo
  success 0 "Setup completed successfully!"
  success 0 "Happy coding!"
  echo
}

main() {
  on_start "$*"
  setup_system "$*"
  install_cli_tools "$*"
  install_homebrew "$*"
  install_git "$*"
  install_dotfiles "$*"
  update_homebrew
  install_zsh "$*"
  install_misc "$*"
  update_vscode_settings
  on_finish "$*"
}

main "$*"
