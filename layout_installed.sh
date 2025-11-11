#!/bin/bash

# This script backs up the list of installed packages from various package managers
# Supported package managers: pacman, AUR, flatpak, snap, apt

# 顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOGFILE="./installed_packages.log"

HAVE_PACMAN=0
HAVE_AUR=0
HAVE_FLATPAK=0
HAVE_SNAP=0
HAVE_APT=0

check_log_file_exists(){
  # Check if log file already exists
  # if it does, notify the user that it will be overwritten
  # if not, create the log file
  if [ -f "$LOGFILE" ]; then
    echo -e "${YELLOW}Warning: Log file $LOGFILE already exists and will be overwritten.${NC}"
  else
    touch "$LOGFILE"
    echo -e "${GREEN}Log file $LOGFILE created.${NC}"
  fi
}

get_pacman_installed_packages(){
  #pacman -Qqe
  pacman -Qqe >> "$LOGFILE"
  echo "Pacman installed packages have been logged to $LOGFILE"
}

get_aur_installed_packages(){
  #pacman -Qqem
  pacman -Qqem >> "$LOGFILE"
  echo "AUR installed packages have been logged to $LOGFILE"
}

get_flatpak_installed_packages(){
  flatpak list --app >> "$LOGFILE"
  echo "Flatpak installed packages have been logged to $LOGFILE"
}

get_apt_installed_packages(){
  dpkg --get-selections | grep -v deinstall >> "$LOGFILE"
  echo "APT installed packages have been logged to $LOGFILE"
}

get_snap_installed_packages(){
  snap list >> "$LOGFILE"
  echo "Snap installed packages have been logged to $LOGFILE"
}

check_package_managers(){
  if command -v pacman &> /dev/null; then
    HAVE_PACMAN=1
  fi

  if command -v yay &> /dev/null || command -v paru &> /dev/null; then
    HAVE_AUR=1
  fi

  if command -v flatpak &> /dev/null; then
    HAVE_FLATPAK=1
  fi

  if command -v snap &> /dev/null; then
    HAVE_SNAP=1
  fi

  if command -v apt &> /dev/null; then
    HAVE_APT=1
  fi
}

main(){
  check_log_file_exists
  check_package_managers
  
  #========clean log file========
  > "$LOGFILE"
  #==============================

  #date tag to logfile
  echo -e "=== Installed Packages Backup - $(date) ===" >> "$LOGFILE"

  #echo existing package managers
  echo -e "${BLUE}Detected package managers:${NC}"
  if [ $HAVE_PACMAN -eq 1 ]; then
    echo -e "${GREEN}- Pacman${NC}"
  fi
  if [ $HAVE_AUR -eq 1 ]; then
    echo -e "${GREEN}- AUR${NC}"
  fi
  if [ $HAVE_FLATPAK -eq 1 ]; then
    echo -e "${GREEN}- Flatpak${NC}"
  fi
  if [ $HAVE_SNAP -eq 1 ]; then
    echo -e "${GREEN}- Snap${NC}"
  fi
  if [ $HAVE_APT -eq 1 ]; then
    echo -e "${GREEN}- APT${NC}"
  fi

  if [ $HAVE_PACMAN -eq 1 ]; then
    echo -e "${BLUE}Backing up Pacman installed packages...${NC}"
    echo -e "\n=== Pacman Installed Packages ===" >> "$LOGFILE"
    get_pacman_installed_packages
  fi

  if [ $HAVE_AUR -eq 1 ]; then
    echo -e "${BLUE}Backing up AUR installed packages...${NC}"
    echo -e "\n=== AUR Installed Packages ===" >> "$LOGFILE"
    get_aur_installed_packages
  fi

  if [ $HAVE_FLATPAK -eq 1 ]; then
    echo -e "${BLUE}Backing up Flatpak installed packages...${NC}"
    echo -e "\n=== Flatpak Installed Packages ===" >> "$LOGFILE"
    get_flatpak_installed_packages
  fi

  if [ $HAVE_SNAP -eq 1 ]; then
    echo -e "${BLUE}Backing up Snap installed packages...${NC}"
    echo -e "\n=== Snap Installed Packages ===" >> "$LOGFILE"
    get_snap_installed_packages
  fi

  if [ $HAVE_APT -eq 1 ]; then
    echo -e "${BLUE}Backing up APT installed packages...${NC}"
    echo -e "\n=== APT Installed Packages ===" >> "$LOGFILE"
    get_apt_installed_packages
  fi

  echo -e "${GREEN}Backup completed. Check the log file at $LOGFILE${NC}"
  echo -e "========================================\n" >> "$LOGFILE"

}

main