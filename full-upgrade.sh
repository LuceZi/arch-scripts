#!/bin/bash

set -e

#=========================
# 顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#=========================
# 日誌檔案設定
active_log(){
    log_file="./log_files/full-upgrade-$(date +'%Y%m%d_%H%M%S').log"
    if [ ! -d "./log_files" ]; then
        mkdir -p "./log_files"
        echo -e "${YELLOW} 已建立日誌目錄: ./log_files ${NC}"
    fi
    echo -e "${YELLOW} 日誌檔案: $log_file ${NC}"
    echo -e"" 
    exec > >(tee -a "$log_file") 2>&1
}

#=========================
# 函數定義

 # 函數：同步 NTP 時間
ntp_sync() {
    echo -e "${BLUE} 同步 NTP 時間${NC}"
    sudo timedatectl set-ntp true
    echo -e "${YELLOW} NTP 同步狀態: $(timedatectl show -p NTPSynchronized --value)${NC}"
    if [ "$(timedatectl show -p NTPSynchronized --value)" != "yes" ]; then
        echo -e "${RED} 警告: NTP 同步失敗，請檢查網路連線或 NTP 設定${NC}"
        exit 1
    else
        echo -e "${GREEN} NTP 時間同步完成\n${NC}"
    fi
}

 # 函數：更新官方套件庫
pacman_update() {
    echo -e "${BLUE} 更新官方套件庫 (pacman -Syu)${NC}"
    sudo pacman -Syu --noconfirm
    echo -e "${GREEN} 官方套件庫更新完成\n${NC}"
}

pacman_clean_orphans() {
    echo -e "${BLUE} 清理孤立的套件 (pacman -Qdtq)${NC}"
    if pacman -Qdtq &>/dev/null; then
        sudo pacman -Rns --noconfirm $(pacman -Qdtq)
        echo -e "${GREEN} 孤立套件清理完成\n${NC}"
    else
        echo -e "${GREEN} 沒有孤立的套件需要移除\n${NC}"
    fi
}

pacman_clean_cache() {
    echo -e "${BLUE} 清理 Pacman 緩存 (paccache -r)${NC}"
    sudo paccache -r -k1  # 僅保留最新 kn 個版本
    echo -e "${GREEN} Pacman 緩存清理完成\n${NC}"
}

# 函數：更新 AUR 套件
aur_update(){
    if command -v yay &>/dev/null; then
        echo -e "${BLUE} 更新 AUR 套件（如果有 yay）${NC}"
        yay -Syu --noconfirm --removemake --answerdiff N --answerclean N
        echo -e "${GREEN} AUR 套件更新完成\n${NC}"
    else
        echo "${RED} 未安裝 yay，跳過 AUR 更新\n${NC}"
    fi
}

aur_clean(){
    if command -v yay &>/dev/null; then
        echo -e "${BLUE} 清理 AUR 套件緩存${NC}"
        yay -Sc --noconfirm
        echo -e "${GREEN} AUR 套件緩存清理完成\n${NC}"
    else
        echo "${RED} 未安裝 yay，跳過 AUR 緩存清理\n${NC}"
    fi
}

# 函數：更新 Flatpak 應用程式
flatpak_update() {
    if command -v flatpak &>/dev/null; then
        echo -e "${BLUE} 更新 Flatpak 應用程式${NC}"
        flatpak update -y
        echo -e "${GREEN} Flatpak 應用程式更新完成\n${NC}"
    else
        echo "${RED} Flatpak 未安裝，跳過此步驟\n${NC}"
    fi
}

flatpak_clean() {
    if command -v flatpak &>/dev/null; then
        echo -e "${BLUE} 清理 Flatpak 應用程式緩存${NC}"
        flatpak uninstall --unused -y
        echo -e "${GREEN} Flatpak 應用程式緩存清理完成\n${NC}"
    else
        echo "${RED} Flatpak 未安裝，跳過此步驟\n${NC}"
    fi
}

 # 函數：檢查並修復系統檔案
check_system_files() {
    echo -e "${BLUE} 檢查並修復系統檔案 (pacman -Qkk)${NC}"
    echo -e "${YELLOW} 檢查系統檔案完整性...${NC}"

    if sudo pacman -Qkk 2>&1 | grep -q -v "0 個檔案經修改\|0 altered files\|0 missing files"; then
        echo -e "${RED} 發現檔案問題，詳細信息：${NC}"
        sudo pacman -Qkk 2>&1 | grep -v "0 個檔案經修改\|0 altered files\|0 missing files"
    else
        echo -e "${GREEN} 系統檔案檢查正常\n${NC}"
    fi
}

#=========================

rebuild_dkms() {
    echo -e "${BLUE} 重新編譯 DKMS 模組（如果有）${NC}"
    if command -v dkms &>/dev/null; then
        local dkms_modules=$(dkms status | awk '{print $1}')
        if [ -n "$dkms_modules" ]; then
            for module in $dkms_modules; do
                echo -e "${YELLOW} 重新編譯 $module...${NC}"
                set +e  # 暫時禁用 set -e
                sudo dkms autoinstall || echo -e "${RED} 模組 $module 重新編譯失敗，繼續執行其他操作...${NC}"
                set -e  # 恢復 set -e
            done
            echo -e "${GREEN} DKMS 模組重新編譯完成\n${NC}"
        else
            echo -e "${GREEN} 沒有 DKMS 模組需要重新編譯\n${NC}"
        fi
    else
        echo -e "${RED} DKMS 未安裝，跳過此步驟\n${NC}"
    fi
}

reboot_request() {
    echo -e "${YELLOW} 系統更新完成，建議重新啟動以應用所有變更。${NC}"
    read -p "是否立即重新啟動？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE} 系統正在重新啟動...${NC}"
        sudo reboot
    else
        echo -e "${BLUE} 請記得稍後手動重新啟動系統以應用更新。${NC}"
    fi
}

show_help() {
    echo "使用方法: $0 [選項]"
    echo "選項:"
    echo "  --ntp-sync          同步 NTP 時間"
    echo "  --update-pacman     更新官方套件庫"
    echo "  --update-aur        更新 AUR 套件（需要 yay）"
    echo "  --update-flatpak    更新 Flatpak 應用程式"
    echo "  --clean-orphans     清理孤立的套件"
    echo "  --check-system      檢查並修復系統檔案"
    echo "  --clean-cache       清理 Pacman 緩存"
    echo "  --rebuild-dkms      重新編譯 DKMS 模組"
    echo "  -a, --all           執行所有更新和清理操作"
    echo "  -h, --help          顯示此幫助訊息"
}

#=========================
# 主程式邏輯
main(){
    case "${1:-help}" in
        --ntp-sync)
            ntp_sync
            ;;
        --update-pacman)
            pacman_update
            ;;
        --update-aur)
            aur_update
            ;;
        --update-flatpak)
            flatpak_update
            ;;
        --clean-orphans)
            pacman_clean_orphans
            ;;
        --check-system)
            check_system_files
            ;;
        --clean-cache)
            pacman_clean_cache
            aur_clean
            flatpak_clean
            ;;
        --rebuild-dkms)
            rebuild_dkms
            ;;
        --a|--all)
            ntp_sync
            pacman_update
            aur_update
            flatpak_update
            pacman_clean_orphans
            pacman_clean_cache
            aur_clean
            flatpak_clean
            rebuild_dkms
            reboot_request
            ;;
        -h|--help|help)
            show_help
            ;;
        *)
            echo -e "${RED} 未知選項: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"