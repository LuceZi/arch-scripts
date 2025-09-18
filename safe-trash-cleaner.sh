#!/bin/bash
# safe-trash-cleaner.sh - 安全垃圾桶清理工具
# 支援多種垃圾桶標準和安全確認

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 垃圾桶路徑（支援多種標準）
TRASH_DIRS=(
    "$HOME/.local/share/Trash"
    "$HOME/.Trash"
    "/tmp/.Trash-$UID"
)

# 顯示檔案大小的函數
human_readable_size() {
    local bytes=$1
    if [ $bytes -ge 1073741824 ]; then
        echo "$(echo "scale=1; $bytes/1073741824" | bc -l 2>/dev/null || echo $(($bytes/1073741824)))GB"
    elif [ $bytes -ge 1048576 ]; then
        echo "$(echo "scale=1; $bytes/1048576" | bc -l 2>/dev/null || echo $(($bytes/1048576)))MB"
    elif [ $bytes -ge 1024 ]; then
        echo "$(echo "scale=1; $bytes/1024" | bc -l 2>/dev/null || echo $(($bytes/1024)))KB"
    else
        echo "${bytes}B"
    fi
}

# 計算目錄大小和檔案數量
calculate_trash_stats() {
    local trash_dir=$1
    local files_dir="$trash_dir/files"
    local info_dir="$trash_dir/info"

    if [ ! -d "$files_dir" ]; then
        echo "0 0"
        return
    fi

    local file_count=0
    local total_size=0

    # 計算檔案數量和大小
    if [ -n "$(ls -A "$files_dir" 2>/dev/null)" ]; then
        file_count=$(find "$files_dir" -type f | wc -l)
        total_size=$(du -sb "$files_dir" 2>/dev/null | cut -f1 || echo "0")
    fi

    echo "$file_count $total_size"
}

# 顯示垃圾桶狀態
show_trash_status() {
    echo -e "${BLUE} 垃圾桶狀態檢查${NC}"
    echo ""

    local total_files=0
    local total_size=0
    local found_trash=false

    for trash_dir in "${TRASH_DIRS[@]}"; do
        if [ -d "$trash_dir" ]; then
            found_trash=true
            local stats=$(calculate_trash_stats "$trash_dir")
            local files=$(echo $stats | cut -d' ' -f1)
            local size=$(echo $stats | cut -d' ' -f2)

            if [ $files -gt 0 ]; then
                echo -e "$trash_dir"
                echo -e "檔案數量: ${YELLOW}$files${NC}"
                echo -e "佔用空間: ${YELLOW}$(human_readable_size $size)${NC}"
                echo ""

                total_files=$((total_files + files))
                total_size=$((total_size + size))
            fi
        fi
    done

    if [ "$found_trash" = false ]; then
        echo -e "${RED} 找不到任何垃圾桶目錄${NC}"
        return 1
    fi

    if [ $total_files -eq 0 ]; then
        echo -e "${GREEN} 垃圾桶是空的，無需清理${NC}"
        return 0
    fi

    echo -e "${BLUE} 總計${NC}"
    echo -e "總檔案數: ${YELLOW}$total_files${NC}"
    echo -e "總大小: ${YELLOW}$(human_readable_size $total_size)${NC}"
    echo ""

    return 0
}

# 清理單個垃圾桶
clean_single_trash() {
    local trash_dir=$1
    local files_dir="$trash_dir/files"
    local info_dir="$trash_dir/info"

    if [ ! -d "$trash_dir" ]; then
        return 0
    fi

    local stats=$(calculate_trash_stats "$trash_dir")
    local files=$(echo $stats | cut -d' ' -f1)

    if [ $files -eq 0 ]; then
        return 0
    fi

    echo -e "${YELLOW}🧹 清理 $trash_dir${NC}"

    # 清理檔案
    if [ -d "$files_dir" ] && [ -n "$(ls -A "$files_dir" 2>/dev/null)" ]; then
        if rm -rf "$files_dir"/* 2>/dev/null; then
            echo -e "已清理檔案目錄"
        else
            echo -e "${RED} 清理檔案目錄失敗${NC}"
            return 1
        fi
    fi

    # 清理資訊檔案
    if [ -d "$info_dir" ] && [ -n "$(ls -A "$info_dir" 2>/dev/null)" ]; then
        if rm -rf "$info_dir"/* 2>/dev/null; then
            echo -e "已清理資訊目錄"
        else
            echo -e "${RED} 清理資訊目錄失敗${NC}"
            return 1
        fi
    fi

    return 0
}

# 主清理函數
clean_trash() {
    local force_mode=false

    # 檢查是否為強制模式
    if [[ "$1" == "--force" || "$1" == "-f" ]]; then
        force_mode=true
    fi

    # 顯示當前狀態
    if ! show_trash_status; then
        exit 1
    fi

    # 計算總數
    local total_files=0
    for trash_dir in "${TRASH_DIRS[@]}"; do
        if [ -d "$trash_dir" ]; then
            local stats=$(calculate_trash_stats "$trash_dir")
            local files=$(echo $stats | cut -d' ' -f1)
            total_files=$((total_files + files))
        fi
    done

    if [ $total_files -eq 0 ]; then
        exit 0
    fi

    # 確認清理
    if [ "$force_mode" = false ]; then
        echo -e "${YELLOW}  警告：此操作將永久刪除垃圾桶中的所有檔案！${NC}"
        echo ""
        read -p "確定要繼續嗎？(y/N): " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE} 操作已取消${NC}"
            exit 0
        fi
    fi

    echo ""
    echo -e "${BLUE} 開始清理垃圾桶...${NC}"
    echo ""

    # 執行清理
    local success_count=0
    local total_count=0

    for trash_dir in "${TRASH_DIRS[@]}"; do
        if [ -d "$trash_dir" ]; then
            local stats=$(calculate_trash_stats "$trash_dir")
            local files=$(echo $stats | cut -d' ' -f1)

            if [ $files -gt 0 ]; then
                total_count=$((total_count + 1))
                if clean_single_trash "$trash_dir"; then
                    success_count=$((success_count + 1))
                fi
            fi
        fi
    done

    echo ""

    # 結果報告
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN} 垃圾桶清理完成！${NC}"
        echo -e "已清理 $total_count 個垃圾桶目錄"
    else
        echo -e "${YELLOW} 清理部分完成${NC}"
        echo -e "成功：$success_count/$total_count"
    fi
}

# 顯示使用說明
show_help() {
    echo -e "${BLUE} 安全垃圾桶清理工具${NC}"
    echo ""
    echo -e "${YELLOW}用法：${NC}"
    echo "$0                - 查看垃圾桶狀態並確認清理"
    echo "$0 clean          - 清理垃圾桶（需要確認）"
    echo "$0 clean --force  - 強制清理垃圾桶（無需確認）"
    echo "$0 status         - 僅查看垃圾桶狀態"
    echo "$0 --help         - 顯示此說明"
    echo ""
    echo -e "${BLUE} 說明：${NC}"
    echo "• 支援多種垃圾桶標準 (FreeDesktop, macOS 風格等)"
    echo "• 清理前會顯示檔案數量和大小"
    echo "• 預設需要用戶確認才執行清理"
    echo "• 使用 --force 參數可跳過確認（適合腳本調用）"
    echo ""
}

# 主程式
main() {
    case "${1:-help}" in
        clean)
            clean_trash "$2"
            ;;
        status)
            show_trash_status
            ;;
        --help | -h | help)
            show_help
            ;;
        *)
            # 預設行為：顯示狀態並詢問是否清理
            if show_trash_status; then
                echo -e "${YELLOW} 執行清理請使用：$0 clean${NC}"
            fi
            ;;
    esac
}

# 執行主程式
main "$@"
