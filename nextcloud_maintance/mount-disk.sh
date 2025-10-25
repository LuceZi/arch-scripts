#!/bin/bash

# NextcloudPi mount disk script
# This script mounts the Nextcloud data and backup disks.
# It is intended to be run at system startup.

LOGFILE="/var/log/ncp-cron.log"

ncp_data="/srv/nextcloud_data"
ncp_backups="/mnt/USBdrive/ncp-backups"

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

echo -e "${LOG_BLUE} mount-disk.sh: Starting disk mount process...${LOG_NC}"

mount_data(){
    if lsblk | grep -q "sda1"; then
      if ! mountpoint -q "$ncp_data"; then
        log " Mounting /dev/sda1 → $ncp_data"
        sudo mkdir -p "$ncp_data"
        if sudo mount /dev/sda1 "$ncp_data"; then
            log " $ncp_data mounted successfully"
        else
            log "${LOG_RED} Failed to mount $ncp_data${LOG_NC}"
        fi
      else
        log " $ncp_data is already mounted"
      fi
    else
      log "/dev/sda1 not found, skipping data disk mount"
    fi
}

mount_ncp_backups(){
    if lsblk | grep -q "sdb1"; then
      if ! mountpoint -q "$ncp_backups"; then
        log " Mounting /dev/sdb1 → $ncp_backups"
        sudo mkdir -p "$ncp_backups"
        if sudo mount /dev/sdb1 "$ncp_backups"; then
            log " $ncp_backups mounted successfully"
        else
            log "${LOG_RED} Failed to mount $ncp_backups${LOG_NC}"
        fi
      else
        log " $ncp_backups is already mounted"
      fi
    else
      log "/dev/sdb1 not found, skipping backup disk mount"
    fi
}

main(){
    mount_data
    mount_ncp_backups
    log " All mount operations completed"
}

main
