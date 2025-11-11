#!/bin/bash

# Audio Driver Check Script
# This script checks for the presence of common audio drivers and logs the results.
# ALSA JACK PulseAudio PipeWire

LOGFILE="/var/log/audio-driver-check.log"

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

#================ Functions =================#
# Check for ALSA driver
check_alsa_loaded() {
    if lsmod | grep -q '^snd'; then
        echo -e "${LOG_GREEN}ALSA driver is loaded.${LOG_NC}"
    else
        echo -e "${LOG_RED}ALSA driver is NOT loaded.${LOG_NC}"
    fi
}

get_alsa_version() {
    local alsa_version
    alsa_version=$(cat /proc/asound/version 2>/dev/null)
    if [ -n "$alsa_version" ]; then
        echo -e "${LOG_GREEN}ALSA version: $alsa_version${LOG_NC}"
    else
        echo -e "${LOG_RED}Could not determine ALSA version.${LOG_NC}"
    fi
}

get_alsa_installed_packages() {
    local alsa_packages
    alsa_packages=$(pacman -Qq | grep '^alsa-')
    if [ -n "$alsa_packages" ]; then
        echo -e "${LOG_GREEN}Installed ALSA packages:${LOG_NC}"
        echo "$alsa_packages"
    else
        echo -e "${LOG_RED}No ALSA packages are installed.${LOG_NC}"
    fi
}

#Jack
check_jack_loaded() {
    if lsmod | grep -q '^jack'; then
        echo -e "${LOG_GREEN}JACK driver is loaded.${LOG_NC}"
    else
        echo -e "${LOG_RED}JACK driver is NOT loaded.${LOG_NC}"
    fi
}

get_jack_version() {
    local jack_version
    jack_version=$(jackd --version 2>/dev/null)
    if [ -n "$jack_version" ]; then
        echo -e "${LOG_GREEN}JACK version: $jack_version${LOG_NC}"
    else
        echo -e "${LOG_RED}Could not determine JACK version.${LOG_NC}"
    fi
}

get_jack_installed_packages() {
    local jack_packages
    jack_packages=$(pacman -Qq | grep '^jack-')
    if [ -n "$jack_packages" ]; then
        echo -e "${LOG_GREEN}Installed JACK packages:${LOG_NC}"
        echo "$jack_packages"
    else
        echo -e "${LOG_RED}No JACK packages are installed.${LOG_NC}"
    fi
}

#pluseaudio
check_pluseaudio_loaded() {
    if pgrep -x "pulseaudio" > /dev/null; then
        echo -e "${LOG_GREEN}PulseAudio is running.${LOG_NC}"
    else
        echo -e "${LOG_RED}PulseAudio is NOT running.${LOG_NC}"
    fi
}

get_pluseaudio_version() {
    local pulseaudio_version
    pulseaudio_version=$(pulseaudio --version 2>/dev/null)
    if [ -n "$pulseaudio_version" ]; then
        echo -e "${LOG_GREEN}PulseAudio version: $pulseaudio_version${LOG_NC}"
    else
        echo -e "${LOG_RED}Could not determine PulseAudio version.${LOG_NC}"
    fi
}
get_pluseaudio_installed_packages() {
    local pulseaudio_packages
    pulseaudio_packages=$(pacman -Qq | grep '^pulseaudio-')
    if [ -n "$pulseaudio_packages" ]; then
        echo -e "${LOG_GREEN}Installed PulseAudio packages:${LOG_NC}"
        echo "$pulseaudio_packages"
    else
        echo -e "${LOG_RED}No PulseAudio packages are installed.${LOG_NC}"
    fi
}

#pipewire
check_pipewire_loaded() {
    if pgrep -x "pipewire" > /dev/null; then
        echo -e "${LOG_GREEN}PipeWire is running.${LOG_NC}"
    else
        echo -e "${LOG_RED}PipeWire is NOT running.${LOG_NC}"
    fi
}

get_pipewire_version() {
    # TODO
    local pipewire_version
    pipewire_version=$(pipewire --version 2>/dev/null)
    if [ -n "$pipewire_version" ]; then
        echo -e "${LOG_GREEN}PipeWire version: $pipewire_version${LOG_NC}"
    else
        echo -e "${LOG_RED}Could not determine PipeWire version.${LOG_NC}"
    fi
}

get_pipewire_installed_packages() {
    # TODO
    local pipewire_packages
    pipewire_packages=$(pacman -Qq | grep '^pipewire-')
    if [ -n "$pipewire_packages" ]; then
        echo -e "${LOG_GREEN}Installed PipeWire packages:${LOG_NC}"
        echo "$pipewire_packages"
    else
        echo -e "${LOG_RED}No PipeWire packages are installed.${LOG_NC}"
    fi
}

get_other_audio_drivers() {
  local other_drivers
  other_drivers=$(lsmod | grep -E '^(snd|jack|pulseaudio|pipewire|libldac|libfreeaptx|bluez_aptx|bluez_aptx_hd|btusb|btrtl|btbcm|btintel|hci_uart)' | awk '{print $1}')
  echo -e "${LOG_BLUE}Other audio-related drivers loaded:${LOG_NC}"
  echo "$other_drivers"
}


check_full_loaded() {
    check_alsa_loaded
    get_alsa_version
    get_alsa_installed_packages

    check_jack_loaded
    get_jack_version
    get_jack_installed_packages

    check_pluseaudio_loaded
    get_pluseaudio_version
    get_pluseaudio_installed_packages

    check_pipewire_loaded
    get_pipewire_version
    get_pipewire_installed_packages
    get_other_audio_drivers
}
#================ Main Script =================#
check_full_loaded
