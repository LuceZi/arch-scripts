#!/bin/bash

# NextcloudPi light Cron Job
# This script performs light maintenance tasks for Nextcloud.
# It is intended to be run hourly via cron.

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

rtc_sync(){
    echo -e "${LOG_BLUE} Starting RTC sync...${LOG_NC}"
    if ! /sbin/hwclock -w; then
        echo -e "${LOG_RED} RTC sync failed.${LOG_NC}"
    else
        echo -e "${LOG_GREEN} RTC sync completed successfully.${LOG_NC}"
    fi
}

self_test(){
    local LOGFILE="/var/log/ncp-selftest.log"
    
    echo -e "${LOG_BLUE} Starting self-test...${LOG_NC}"
    echo "=== Nextcloud Health Check - $(date) ===" >> "$LOGFILE"
    
    # apache2 狀態
    echo -e "${LOG_BLUE} Checking Apache2 status...${LOG_NC}"
    if ! systemctl is-active --quiet apache2; then
        echo -e "${LOG_RED} Apache2 is not active!${LOG_NC}"
    else
        echo -e "${LOG_GREEN} Apache2 is active.${LOG_NC}"
    fi

    # PHP 模組與版本
    echo -e "${LOG_BLUE} Checking PHP version and modules...${LOG_NC}"
    local PHP_BIN="/usr/bin/php"
    $PHP_BIN -v | head -n 1 >> "$LOGFILE"
    echo "[PHP Modules]" >> "$LOGFILE"
    $PHP_BIN -m | grep -E 'gd|xml|zip|bz2|intl|mbstring|curl|imagick|sqlite3|mysql|pgsql' >> "$LOGFILE"

    # MariaDB 狀態
    echo -e "${LOG_BLUE} Checking MariaDB status...${LOG_NC}"
    echo "[MariaDB Status]" >> "$LOGFILE"
    if ! systemctl is-active --quiet mariadb; then
        echo -e "${LOG_RED} MariaDB is not active!${LOG_NC}"
    else
        echo -e "${LOG_GREEN} MariaDB is active.${LOG_NC}"
    fi

    # Nextcloud OCC 狀態
    echo -e "${LOG_BLUE} Checking Nextcloud OCC status...${LOG_NC}"
    if ! sudo -u www-data $PHP_BIN "$NEXTCLOUD_OCC" status >> "$LOGFILE" 2>&1; then
        echo -e "${LOG_RED} OCC status check failed!${LOG_NC}"
    else
        echo -e "${LOG_GREEN} OCC status check completed.${LOG_NC}"
    fi

    # notify_push / mcp 狀態
    echo -e "${LOG_BLUE} Checking notify_push / mcp status...${LOG_NC}"
    if ! systemctl is-active --quiet notify_push; then
        echo -e "${LOG_RED} notify_push is not active!${LOG_NC}"
    else
        echo -e "${LOG_GREEN} notify_push is active.${LOG_NC}"
    fi
    if ! systemctl is-active --quiet mcp; then
        echo -e "${LOG_RED} mcp is not active!${LOG_NC}"
    else
        echo -e "${LOG_GREEN} mcp is active.${LOG_NC}"
    fi

    # 權限檢查
    echo -e "${LOG_BLUE} Checking Nextcloud directory permissions...${LOG_NC}"
    echo "[Nextcloud Directory Permission Check]" >> "$LOGFILE"
    stat -c "%U:%G %a %n" "/var/www/nextcloud/config/config.php" >> "$LOGFILE" 2>/dev/null

    # 磁碟空間 / 記憶體 / CPU
    echo -e "${LOG_BLUE} Checking disk, memory, and CPU usage...${LOG_NC}"
    echo "[Disk Usage]" >> "$LOGFILE"
    df -h / | tail -1 >> "$LOGFILE"
    free -h >> "$LOGFILE"
    uptime >> "$LOGFILE"
    echo "" >> "$LOGFILE"

    echo -e "${LOG_GREEN} Self-test completed. Results logged to ${LOGFILE}.${LOG_NC}"

    if [ $? -eq 0 ]; then
        echo -e "${LOG_GREEN} Self-test completed successfully at $(date '+%Y-%m-%d %H:%M').${LOG_NC}"
    else
        echo -e "${LOG_RED} Self-test encountered errors at $(date '+%Y-%m-%d %H:%M'). Please check the log.${LOG_NC}"
    fi

}

main() {
    log "${LOG_BLUE}=== NextcloudPi Light Cron Job Started ===${LOG_NC}"
    rtc_sync
    echo ""
    self_test
    # 在這裡添加輕量級的維護任務
    log "${LOG_BLUE}=== NextcloudPi Light Cron Job Finished ===${LOG_NC}"
}

main