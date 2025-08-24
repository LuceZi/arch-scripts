#!/bin/bash
# Turbo Boost 控制器 🖥️ Luce Edition

set -e

# 控制檔案路徑
TURBO_STATUS_FILE="/sys/devices/system/cpu/intel_pstate/no_turbo"
CPUINFO_MAX_FREQ="/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
SCALING_MAX_FREQ="/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 檢查系統相容性
check_compatibility() {
    if [ ! -f "$TURBO_STATUS_FILE" ]; then
        echo -e "${RED}❌ 錯誤：找不到 Turbo Boost 控制檔案${NC}"
        echo "   檔案路徑：$TURBO_STATUS_FILE"
        echo ""
        echo -e "${YELLOW}💡 可能的原因：${NC}"
        echo "   1. 您的 CPU 不支援 Intel P-State 驅動"
        echo "   2. 系統使用其他 CPU 頻率調節器"
        echo "   3. BIOS 中已關閉 Turbo Boost"
        echo ""
        echo -e "${BLUE}🔍 替代檢查方法：${NC}"
        echo "   查看 CPU 資訊：lscpu | grep -E '(Model name|MHz)'"
        echo "   查看可用調節器：cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null"
        exit 1
    fi
}

# 顯示 CPU 資訊
show_cpu_info() {
    echo -e "${BLUE}🖥️  CPU 資訊：${NC}"
    
    # CPU 型號
    cpu_model=$(lscpu | grep "Model name" | sed 's/Model name:\s*//')
    echo "   型號：$cpu_model"
    
    # 基礎頻率和最大頻率
    if [ -f "$CPUINFO_MAX_FREQ" ]; then
        max_freq=$(cat "$CPUINFO_MAX_FREQ")
        max_freq_ghz=$(echo "scale=2; $max_freq / 1000000" | bc -l 2>/dev/null || echo "$(($max_freq / 1000000))")
        echo "   最大頻率：${max_freq_ghz} GHz"
    fi
    
    # 當前頻率
    if [ -f "$SCALING_MAX_FREQ" ]; then
        current_max=$(cat "$SCALING_MAX_FREQ")
        current_max_ghz=$(echo "scale=2; $current_max / 1000000" | bc -l 2>/dev/null || echo "$(($current_max / 1000000))")
        echo "   當前最大頻率：${current_max_ghz} GHz"
    fi
    
    echo ""
}

# 檢查當前狀態
get_turbo_status() {
    cat "$TURBO_STATUS_FILE"
}

# 顯示詳細狀態
show_detailed_status() {
    local current_status=$(get_turbo_status)
    
    echo -e "${BLUE}📊 Turbo Boost 狀態詳情：${NC}"
    
    if [ "$current_status" == "1" ]; then
        echo -e "   狀態：${RED}已關閉 ❌${NC}"
        echo "   效果：CPU 將限制在基礎頻率運行"
        echo "   優點：降低功耗、減少發熱"
    else
        echo -e "   狀態：${GREEN}已開啟 🚀${NC}"
        echo "   效果：CPU 可以超過基礎頻率運行"
        echo "   優點：提供更高的性能表現"
    fi
    
    echo ""
}

# 主要功能
main() {
    check_compatibility
    
    case "$1" in
        disable)
            echo -e "${YELLOW}🔧 正在關閉 Turbo Boost...${NC}"
            if echo 1 | sudo tee "$TURBO_STATUS_FILE" > /dev/null; then
                echo -e "${GREEN}✅ Turbo Boost 已關閉${NC}"
                echo "   CPU 將限制在基礎頻率運行，有助於節能和降溫"
            else
                echo -e "${RED}❌ 關閉 Turbo Boost 失敗${NC}"
                exit 1
            fi
            ;;
        enable)
            echo -e "${YELLOW}🔧 正在開啟 Turbo Boost...${NC}"
            if echo 0 | sudo tee "$TURBO_STATUS_FILE" > /dev/null; then
                echo -e "${GREEN}🚀 Turbo Boost 已開啟${NC}"
                echo "   CPU 可以超過基礎頻率運行，提供更高性能"
            else
                echo -e "${RED}❌ 開啟 Turbo Boost 失敗${NC}"
                exit 1
            fi
            ;;
        status|info)
            show_cpu_info
            show_detailed_status
            ;;
        toggle)
            current_status=$(get_turbo_status)
            if [ "$current_status" == "1" ]; then
                echo -e "${YELLOW}🔄 切換：開啟 Turbo Boost${NC}"
                echo 0 | sudo tee "$TURBO_STATUS_FILE" > /dev/null
                echo -e "${GREEN}🚀 Turbo Boost 已開啟${NC}"
            else
                echo -e "${YELLOW}🔄 切換：關閉 Turbo Boost${NC}"
                echo 1 | sudo tee "$TURBO_STATUS_FILE" > /dev/null
                echo -e "${GREEN}✅ Turbo Boost 已關閉${NC}"
            fi
            ;;
        *)
            echo -e "${BLUE}🖥️  Turbo Boost 控制器 - Luce Edition${NC}"
            echo ""
            echo -e "${YELLOW}用法：${NC}"
            echo "  $0 enable    - 開啟 Turbo Boost 🚀"
            echo "  $0 disable   - 關閉 Turbo Boost ✅"
            echo "  $0 status    - 查看詳細狀態 📊"
            echo "  $0 info      - 查看詳細狀態 📊 (同 status)"
            echo "  $0 toggle    - 切換開關狀態 🔄"
            echo ""
            echo -e "${BLUE}💡 小提示：${NC}"
            echo "  • 關閉 Turbo Boost 可以節省電力並降低溫度"
            echo "  • 開啟 Turbo Boost 可以獲得更高的 CPU 性能"
            echo "  • 建議在筆電使用電池時關閉以延長續航"
            echo ""
            exit 1
            ;;
    esac
}

# 執行主函數
main "$@"
