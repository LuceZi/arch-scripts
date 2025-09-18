#!/bin/bash

# 顏色定義（可選）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 正在檢查 VMware 服務狀態..."

# 檢查是否為 root 權限（某些操作需要）
check_root_needed() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        echo "此腳本需要 sudo 權限來載入模組和啟動服務"
    fi
}

# 檢查並載入核心模組的函數
load_module() {
    local module_name=$1
    local display_name=$2
    
    if ! lsmod | grep -q "^$module_name "; then
        echo "$display_name 模組未載入，正在載入..."
        if sudo modprobe "$module_name" 2>/dev/null; then
            echo "$display_name 模組載入成功"
        else
            echo "$display_name 模組載入失敗"
            echo "提示：可能需要重新編譯 VMware 模組或檢查 DKMS"
            return 1
        fi
    else
        echo "$display_name 模組已載入"
    fi
    return 0
}

# 檢查並啟動服務的函數
start_service() {
    local service_name=$1
    local display_name=$2
    
    if ! systemctl is-active --quiet "$service_name"; then
        echo "$display_name 未啟動，正在啟動..."
        if sudo systemctl start "$service_name" 2>/dev/null; then
            echo "$display_name 啟動成功"
        else
            echo "$display_name 啟動失敗"
            echo "提示：檢查服務狀態 - systemctl status $service_name"
            return 1
        fi
    else
        echo "$display_name 已在運行中"
    fi
    return 0
}

# 主要檢查流程
main() {
    local error_count=0
    
    check_root_needed
    
    echo ""
    echo "檢查 VMware 核心模組..."
    load_module "vmmon" "VMware Monitor" || ((error_count++))
    load_module "vmnet" "VMware Network" || ((error_count++))
    
    echo ""
    echo "檢查 VMware 系統服務..."
    
    # VMware 主程式服務（如果存在的話）
    if systemctl list-unit-files | grep -q "vmware.service"; then
        start_service "vmware.service" "VMware 主程式" || ((error_count++))
    else
        echo "VMware 主程式服務不存在（可能是較新版本）"
    fi
    
    # VMware 網路服務
    start_service "vmware-networks.service" "VMware 網路" || ((error_count++))
    
    # VMware USB 仲裁服務
    start_service "vmware-usbarbitrator.service" "VMware USB 掛接" || ((error_count++))
    
    echo ""
    echo "查看最近的 VMware 日誌..."
    
    # 更強健的日誌檢查
    local log_found=false
    for log_dir in "/tmp/vmware-root" "/tmp/vmware-$USER" "/var/log/vmware"; do
        if [[ -d "$log_dir" ]]; then
            local log_files=$(find "$log_dir" -name "*.log" -readable 2>/dev/null | head -3)
            if [[ -n "$log_files" ]]; then
                echo "來自 $log_dir 的最新日誌："
                echo "$log_files" | while read -r logfile; do
                    echo "--- $(basename "$logfile") ---"
                    tail -n 5 "$logfile" 2>/dev/null | head -5
                done
                log_found=true
                break
            fi
        fi
    done
    
    if [[ "$log_found" == false ]]; then
        echo "未找到可讀取的 VMware 日誌檔案"
    fi
    
    echo ""
    
    # 總結
    if [[ $error_count -eq 0 ]]; then
        echo "所有 VMware 相關服務已確認完成！"
    else
        echo "完成檢查，但有 $error_count 個項目需要注意"
        echo "建議檢查 VMware 安裝或重新編譯核心模組"
    fi
    
    # 顯示當前狀態摘要
    echo ""
    echo "當前狀態摘要："
    echo "模組: $(lsmod | grep -E '^(vmmon|vmnet)' | wc -l)/2 已載入"
    echo "服務: $(systemctl is-active vmware-networks vmware-usbarbitrator 2>/dev/null | grep -c active) 個運行中"
}

# 執行主函數
main
