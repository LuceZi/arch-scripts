#!/bin/bash

# Pacman Uninstall Cleaner Script
# This script clean up leftover shortcuts after uninstalling packages with pacman.

LOGFILE="/var/log/pacman-uninstalled-shortcut-cleaner.log"
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

clean_shortcuts() {
    echo -e "${LOG_BLUE}Starting cleanup of leftover shortcuts...${LOG_NC}"
    
    local uninstalled_packages=($(comm -13 <(pacman -Qq | sort) <(grep 'removed' /var/log/pacman.log | awk '{print $NF}' | sort | uniq)))

    if [[ ${#uninstalled_packages[@]} -eq 0 ]]; then
        echo -e "${LOG_BLUE}No leftover shortcuts to clean.${LOG_NC}"
        return
    fi

    for pkg in "${uninstalled_packages[@]}"; do
        echo -e "${LOG_GREEN}Cleaning shortcuts for uninstalled package: $pkg${LOG_NC}"
        # 建議先列出檔案
        find /usr/share/applications/ -name "*$pkg*.desktop" -print
        find ~/.local/share/applications/ -name "*$pkg*.desktop" -print

        # 真正刪除 (需要 root)
        sudo find /usr/share/applications/ -name "*$pkg*.desktop" -exec rm -f {} \;
        find ~/.local/share/applications/ -name "*$pkg*.desktop" -exec rm -f {} \;
    done

    echo -e "${LOG_BLUE}Cleanup completed.${LOG_NC}"
}

clean_shortcuts_old() {
    echo -e "${LOG_BLUE}Starting cleanup of leftover shortcuts...${LOG_NC}"
    local uninstalled_packages=($(comm -13 <(pacman -Qq | sort) <(grep -oP '^\S+' /var/log/pacman.log | sort | uniq)))
    for pkg in "${uninstalled_packages[@]}"; do
        echo -e "${LOG_GREEN}Cleaning shortcuts for uninstalled package: $pkg${LOG_NC}"
        find /usr/share/applications/ -name "*$pkg*.desktop" -exec rm -f {} \;
        find ~/.local/share/applications/ -name "*$pkg*.desktop" -exec rm -f {} \;
    done
    echo -e "${LOG_BLUE}Cleanup completed.${LOG_NC}"
}



check_root
clean_shortcuts