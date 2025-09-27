#!/bin/bash

# NextcloudPi Heavy Cron Job
# This script performs heavy maintenance tasks for Nextcloud.
# It is intended to be run daily via cron.

LOGFILE="/var/log/ncp-cron.log"
NEXTCLOUD_OCC="/var/www/nextcloud/occ"

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

log() {
    echo -e "$(date '+%F %T') $1"
}

file_scan(){
    echo -e "${LOG_BLUE} Starting files:scan --all...${LOG_NC}"
    if ! sudo -u www-data php "$NEXTCLOUD_OCC" files:scan --all; then
        echo -e "${LOG_RED} File scan failed.${LOG_NC}"
    else
        echo -e "${LOG_GREEN} File scan completed successfully.${LOG_NC}"
    fi

}

preview_generate(){
    echo -e "${LOG_BLUE} Starting preview:pre-generate...${LOG_NC}"
    if ! sudo -u www-data php "$NEXTCLOUD_OCC" preview:pre-generate; then
        echo -e "${LOG_RED} Preview pre-generation failed.${LOG_NC}"
    else
        echo -e "${LOG_GREEN} Preview pre-generation completed.${LOG_NC}"
    fi
}

main() {
    log "${LOG_BLUE}=== NextcloudPi Heavy Cron Job Started ===${LOG_NC}"
    file_scan
    preview_generate
    log "${LOG_BLUE}=== NextcloudPi Heavy Cron Job Finished ===${LOG_NC}"
}

main
