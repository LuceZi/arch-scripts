#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：顯示使用方法
show_usage() {
    echo -e "${BLUE}journalctl 管理腳本${NC}"
    echo "用法: $0 [選項]"
    echo ""
    echo "選項:"
    echo "  -s, --status      顯示日誌狀態和大小"
    echo "  -c, --clean       清理日誌（互動式）"
    echo "  -a, --auto-clean  自動清理（保留7天）"
    echo "  -v, --view        查看日誌選項"
    echo "  -h, --help        顯示此幫助資訊"
    echo ""
}

# 函數：顯示日誌狀態
show_status() {
    echo -e "${BLUE}=== journalctl 狀態資訊 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}日誌佔用空間:${NC}"
    journalctl --disk-usage
    echo ""
    
    echo -e "${YELLOW}日誌檔案詳情:${NC}"
    if [ -d "/var/log/journal" ]; then
        sudo find /var/log/journal -name "*.journal*" -exec ls -lh {} \; | head -10
    fi
    echo ""
    
    echo -e "${YELLOW}系統配置:${NC}"
    if [ -f "/etc/systemd/journald.conf" ]; then
        grep -v "^#\|^$" /etc/systemd/journald.conf 2>/dev/null || echo "使用預設配置"
    fi
    echo ""
}

# 函數：互動式清理
interactive_clean() {
    echo -e "${BLUE}=== 日誌清理選項 ===${NC}"
    echo ""
    echo "1) 清理 7 天前的日誌"
    echo "2) 清理 30 天前的日誌"
    echo "3) 限制日誌大小到 500MB"
    echo "4) 限制日誌大小到 1GB"
    echo "5) 自訂清理選項"
    echo "6) 取消"
    echo ""
    
    read -p "請選擇 (1-6): " choice
    
    case $choice in
        1)
            echo -e "${YELLOW}清理 7 天前的日誌...${NC}"
            sudo journalctl --vacuum-time=7d
            ;;
        2)
            echo -e "${YELLOW}清理 30 天前的日誌...${NC}"
            sudo journalctl --vacuum-time=30d
            ;;
        3)
            echo -e "${YELLOW}限制日誌大小到 500MB...${NC}"
            sudo journalctl --vacuum-size=500M
            ;;
        4)
            echo -e "${YELLOW}限制日誌大小到 1GB...${NC}"
            sudo journalctl --vacuum-size=1G
            ;;
        5)
            echo "自訂選項:"
            echo "1) 按時間清理"
            echo "2) 按大小清理"
            read -p "選擇 (1-2): " sub_choice
            
            if [ "$sub_choice" = "1" ]; then
                read -p "輸入保留天數 (例如: 14d, 1month): " time_period
                sudo journalctl --vacuum-time=$time_period
            elif [ "$sub_choice" = "2" ]; then
                read -p "輸入最大大小 (例如: 500M, 2G): " size_limit
                sudo journalctl --vacuum-size=$size_limit
            fi
            ;;
        6)
            echo "取消清理"
            return
            ;;
        *)
            echo -e "${RED}無效選項${NC}"
            return
            ;;
    esac
    
    echo -e "${GREEN}清理完成！${NC}"
    echo ""
    echo -e "${YELLOW}清理後的狀態:${NC}"
    journalctl --disk-usage
}

# 函數：自動清理
auto_clean() {
    echo -e "${YELLOW}自動清理日誌（保留7天）...${NC}"
    
    # 顯示清理前的大小
    echo "清理前："
    journalctl --disk-usage
    
    # 執行清理
    sudo journalctl --vacuum-time=7d
    
    # 顯示清理後的大小
    echo ""
    echo "清理後："
    journalctl --disk-usage
    
    echo -e "${GREEN}自動清理完成！${NC}"
}

# 函數：查看日誌選項
view_logs() {
    echo -e "${BLUE}=== 日誌查看選項 ===${NC}"
    echo ""
    echo "1) 查看最新日誌 (即時)"
    echo "2) 查看系統開機日誌"
    echo "3) 查看錯誤日誌"
    echo "4) 查看特定服務日誌"
    echo "5) 查看指定時間範圍日誌"
    echo "6) 返回"
    echo ""
    
    read -p "請選擇 (1-6): " choice
    
    case $choice in
        1)
            echo -e "${YELLOW}查看即時日誌 (Ctrl+C 退出)...${NC}"
            journalctl -f
            ;;
        2)
            echo -e "${YELLOW}查看開機日誌...${NC}"
            journalctl -b
            ;;
        3)
            echo -e "${YELLOW}查看錯誤日誌...${NC}"
            journalctl -p err
            ;;
        4)
            read -p "輸入服務名稱: " service_name
            echo -e "${YELLOW}查看 $service_name 服務日誌...${NC}"
            journalctl -u $service_name
            ;;
        5)
            echo "時間格式範例: 2024-01-01, '1 hour ago', 'yesterday'"
            read -p "輸入開始時間: " start_time
            read -p "輸入結束時間 (可選): " end_time
            
            if [ -n "$end_time" ]; then
                journalctl --since "$start_time" --until "$end_time"
            else
                journalctl --since "$start_time"
            fi
            ;;
        6)
            return
            ;;
        *)
            echo -e "${RED}無效選項${NC}"
            ;;
    esac
}

# 主程式邏輯
case "$1" in
    -s|--status)
        show_status
        ;;
    -c|--clean)
        interactive_clean
        ;;
    -a|--auto-clean)
        auto_clean
        ;;
    -v|--view)
        view_logs
        ;;
    -h|--help)
        show_usage
        ;;
    "")
        # 沒有參數時顯示互動式選單
        echo -e "${BLUE}=== journalctl 管理工具 ===${NC}"
        echo ""
        echo "1) 查看日誌狀態"
        echo "2) 清理日誌"
        echo "3) 查看日誌"
        echo "4) 自動清理 (保留7天)"
        echo "5) 退出"
        echo ""
        
        read -p "請選擇 (1-5): " main_choice
        
        case $main_choice in
            1) show_status ;;
            2) interactive_clean ;;
            3) view_logs ;;
            4) auto_clean ;;
            5) echo "再見！" ;;
            *) echo -e "${RED}無效選項${NC}" ;;
        esac
        ;;
    *)
        echo -e "${RED}未知選項: $1${NC}"
        show_usage
        exit 1
        ;;
esac