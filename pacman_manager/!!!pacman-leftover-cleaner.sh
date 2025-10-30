#!/bin/bash

# Flatpak Leftover Cleanup Script
# This script cleans up leftover files after uninstalling Flatpak applications.

LOGFILE="/var/log/flatpak-leftover-clean.log"
if [ -t 1 ]; then
    # 手動執行，有彩色輸出
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    LOG_RED=$RED
    LOG_GREEN=$GREEN
    LOG_BLUE=$BLUE
    LOG_NC=$NC
else
    # cron 執行，沒彩色
    exec &>> "$LOGFILE"
    LOG_RED=''
    LOG_GREEN=''
    LOG_BLUE=''
    LOG_NC=''
fi

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${LOG_RED}ERROR: This script must be run as root.${LOG_NC}" >&2
        exit 1
    fi
}

list_pacman_leftovers_folders_old() {
    echo -e "${LOG_BLUE}Listing leftover Pacman files...${LOG_NC}"
    local installed_packages=($(pacman -Qq))
    local leftovers=()

    for dir in /usr/share/applications/*; do
        local filename=$(basename "$dir")
        local pkg_name="${filename%%.*}"
        if [[ ! " ${installed_packages[@]} " =~ " ${pkg_name} " ]]; then
            leftovers+=("$dir")
        fi
    done

    if [[ ${#leftovers[@]} -eq 0 ]]; then
        echo -e "${LOG_BLUE}No leftover Pacman files found.${LOG_NC}"
    else
        echo -e "${LOG_GREEN}Found leftover Pacman files:${LOG_NC}"
        for leftover in "${leftovers[@]}"; do
            echo "$leftover"
        done
    fi
}

list_pacman_leftovers_folders() {
    echo -e "${LOG_BLUE}Listing leftover Pacman files...${LOG_NC}"
    local installed_packages
    installed_packages=($(pacman -Qq))
    local leftovers=()

    for dir in /usr/share/applications/*; do
        [[ -f "$dir" ]] || continue
        local filename=$(basename "$dir")
        local pkg_name="${filename%%.*}"
        if ! printf '%s\n' "${installed_packages[@]}" | grep -Fxq "$pkg_name"; then
            leftovers+=("$dir")
        fi
    done

    if [[ ${#leftovers[@]} -eq 0 ]]; then
        echo -e "${LOG_BLUE}No leftover Pacman files found.${LOG_NC}"
    else
        echo -e "${LOG_GREEN}Found leftover Pacman files:${LOG_NC}"
        for leftover in "${leftovers[@]}"; do
            echo "$leftover"
        done
    fi
}


clean_pacman_leftovers() {
  #do this later
  return
}

check_root
list_pacman_leftovers_folders
#clean_pacman_leftovers