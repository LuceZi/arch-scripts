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

list_flatpak_leftovers() {
    echo -e "${LOG_BLUE}Listing leftover Flatpak files...${LOG_NC}"
    local installed_apps=($(flatpak list --app --columns=application))
    local leftovers=()

    for dir in ~/.var/app/*/; do
        local app_id=$(basename "$dir")
        if [[ ! " ${installed_apps[@]} " =~ " ${app_id} " ]]; then
            leftovers+=("$dir")
        fi
    done

    if [[ ${#leftovers[@]} -eq 0 ]]; then
        echo -e "${LOG_BLUE}No leftover Flatpak files found.${LOG_NC}"
    else
        echo -e "${LOG_GREEN}Found leftover Flatpak files:${LOG_NC}"
        for leftover in "${leftovers[@]}"; do
            echo "$leftover"
        done
    fi
}
clean_flatpak_leftovers() {
    echo -e "${LOG_BLUE}Cleaning up leftover Flatpak files...${LOG_NC}"
    local installed_apps=($(flatpak list --app --columns=application))
    local leftovers=()

    for dir in ~/.var/app/*/; do
        local app_id=$(basename "$dir")
        if [[ ! " ${installed_apps[@]} " =~ " ${app_id} " ]]; then
            leftovers+=("$dir")
        fi
    done

    if [[ ${#leftovers[@]} -eq 0 ]]; then
        echo -e "${LOG_BLUE}No leftover Flatpak files to clean.${LOG_NC}"
        return
    fi

    for leftover in "${leftovers[@]}"; do
        echo -e "${LOG_GREEN}Removing leftover: $leftover${LOG_NC}"
        rm -rf "$leftover"
    done

    echo -e "${LOG_BLUE}Cleanup completed.${LOG_NC}"
}

list_flatpak_leftovers
clean_flatpak_leftovers