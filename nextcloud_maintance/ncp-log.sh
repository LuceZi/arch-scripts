#!/bin/bash

# Raspberry Pi Nextcloud User Script
# This script manages main logs and configurations for Nextcloud Pi. 
# It is intended to be run in manual mode by the user

NEXTCLOUD_OCC="/var/www/nextcloud/occ"
NCP_CONFIG="/var/www/nextcloud/config/config.php"
NCP_LOG="/var/log/ncp-usr.log" # Log file for THIS script

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

find_ncp_log_files() {
    #find log file from config.php
    local log_files=($(php -r "include '$NCP_CONFIG'; \$logs = \$CONFIG['logfile']; echo \$logs;" 2>/dev/null))
    if [ ${#log_files[@]} -eq 0 ]; then
        echo -e "${LOG_RED}ERROR: No log files location found in NextcloudPi configuration.${LOG_NC}" >&2
        exit 1
    fi
    echo -e "${LOG_GREEN}SUCCESS: Nextcloud log file location: ${log_files[*]}${LOG_NC}"

}

check_ncp_log_file_exists() {
    #check exists -y-> return
    #check exists -n-> create log files
    local log_files=($(php -r "include '$NCP_CONFIG'; \$logs = \$CONFIG['logfile']; echo \$logs;" 2>/dev/null))
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            echo -e "${LOG_GREEN}SUCCESS: Log file exists: $log_file${LOG_NC}"
        else
            echo -e "${LOG_RED}WARNING: Log file does not exist: $log_file. Creating...${LOG_NC}"
            touch "$log_file"
            if [ $? -eq 0 ]; then
                echo -e "${LOG_GREEN}SUCCESS: Created log file: $log_file${LOG_NC}"
            else
                echo -e "${LOG_RED}ERROR: Failed to create log file: $log_file${LOG_NC}" >&2
            fi
        fi
    done
}

clean_ncp_logs() {
    #check exists -y-> clean log files
    check_ncp_log_file_exists
    local log_files=($(php -r "include '$NCP_CONFIG'; \$logs = \$CONFIG['logfile']; echo \$logs;" 2>/dev/null))
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            echo -e "${LOG_BLUE}INFO: Cleaning log file: $log_file${LOG_NC}"
            : > "$log_file"
            if [ $? -eq 0 ]; then
                echo -e "${LOG_GREEN}SUCCESS: Cleaned log file: $log_file${LOG_NC}"
            else
                echo -e "${LOG_RED}ERROR: Failed to clean log file: $log_file${LOG_NC}" >&2
            fi
        else
            echo -e "${LOG_RED}ERROR: Log file does not exist, cannot clean: $log_file${LOG_NC}" >&2
        fi
    done
}

fix_ncp_log_permissions() {
    #fix permissions of log files
    #check exists -y-> fix permissions
    check_ncp_log_file_exists
    local log_files=($(php -r "include '$NCP_CONFIG'; \$logs = \$CONFIG['logfile']; echo \$logs;" 2>/dev/null))
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            echo -e "${LOG_BLUE}INFO: Fixing permissions for log file: $log_file${LOG_NC}"
            chown www-data:www-data "$log_file"
            chmod 640 "$log_file"
            if [ $? -eq 0 ]; then
                echo -e "${LOG_GREEN}SUCCESS: Fixed permissions for log file: $log_file${LOG_NC}"
            else
                echo -e "${LOG_RED}ERROR: Failed to fix permissions for log file: $log_file${LOG_NC}" >&2
            fi
        else
            echo -e "${LOG_RED}ERROR: Log file does not exist, cannot fix permissions: $log_file${LOG_NC}" >&2
        fi
    done
}

check_ncp_log_file_permissions() {
    #check permissions of log files
    #check exists -y-> check permissions
    check_ncp_log_file_exists
    local log_files=($(php -r "include '$NCP_CONFIG'; \$logs = \$CONFIG['logfile']; echo \$logs;" 2>/dev/null))
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            local owner_group
            owner_group=$(stat -c "%U:%G" "$log_file")
            local permissions
            permissions=$(stat -c "%a" "$log_file")
            echo -e "${LOG_BLUE}INFO: Log file: $log_file, Owner:Group = $owner_group, Permissions = $permissions${LOG_NC}"
            if [ "$owner_group" != "www-data:www-data" ]; then
                echo -e "${LOG_RED}WARNING: Incorrect owner:group for log file: $log_file (found: $owner_group, expected: www-data:www-data)${LOG_NC}"
                fix_ncp_log_permissions
                echo -e "${LOG_GREEN}SUCCESS: Fixed owner:group for log file: $log_file${LOG_NC}"
            else
                echo -e "${LOG_GREEN}SUCCESS: Correct owner:group for log file: $log_file${LOG_NC}"
            fi
        else
            echo -e "${LOG_RED}ERROR: Log file does not exist, cannot check permissions: $log_file${LOG_NC}" >&2
        fi
    done
}

# Main script execution

choose_action() {
    echo "Select an action:"
    echo "1) Check NextcloudPi log files existence"
    echo "2) Clean NextcloudPi log files"
    echo "3) Fix NextcloudPi log files permissions"
    echo "4) Exit"
    read -rp "Enter your choice [1-4]: " choice

    case $choice in
        1)
            check_ncp_log_file_exists
            ;;
        2)
            clean_ncp_logs
            ;;
        3)
            check_ncp_log_file_permissions
            ;;
        4)
            echo "Exiting script."
            exit 0
            ;;
        *)
            echo "ERROR: Invalid choice. Please select a valid option."
            ;;
    esac
}

check_root
while true; do
    choose_action
done
