#!/bin/bash

# PipeWire 音頻服務管理腳本
# 功能：重啟 PipeWire、PipeWire-Pulse 和 WirePlumber 服務

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查服務狀態
check_service_status() {
    local service=$1
    if systemctl --user is-active --quiet "$service"; then
        echo "running"
    else
        echo "stopped"
    fi
}

# 顯示當前服務狀態
show_status() {
    echo
    log_info "當前 PipeWire 服務狀態："
    echo "  pipewire: $(check_service_status pipewire)"
    echo "  pipewire-pulse: $(check_service_status pipewire-pulse)"
    echo "  wireplumber: $(check_service_status wireplumber)"
    echo
}

# 停止服務
stop_services() {
    log_info "停止 PipeWire 相關服務..."
    
    # 按順序停止服務
    for service in wireplumber pipewire-pulse pipewire; do
        if systemctl --user is-active --quiet "$service"; then
            log_info "停止 $service"
            systemctl --user stop "$service"
            if [ $? -eq 0 ]; then
                log_success "$service 已停止"
            else
                log_error "停止 $service 失敗"
                return 1
            fi
        else
            log_warning "$service 已經停止"
        fi
    done
    
    return 0
}

# 啟動服務
start_services() {
    log_info "啟動 PipeWire 相關服務..."
    
    # 按順序啟動服務
    for service in pipewire pipewire-pulse wireplumber; do
        log_info "啟動 $service"
        systemctl --user start "$service"
        if [ $? -eq 0 ]; then
            log_success "$service 已啟動"
        else
            log_error "啟動 $service 失敗"
            return 1
        fi
        
        # 啟動服務間稍作等待
        sleep 0.5
    done
    
    return 0
}

# 重啟服務
restart_services() {
    log_info "重啟 PipeWire 音頻服務..."
    
    show_status
    
    # 停止服務
    if ! stop_services; then
        log_error "服務停止失敗"
        return 1
    fi
    
    # 等待一秒
    log_info "等待 1 秒..."
    sleep 1
    
    # 啟動服務
    if ! start_services; then
        log_error "服務啟動失敗"
        return 1
    fi
    
    log_success "PipeWire 服務重啟完成！"
    show_status
}

# 顯示幫助信息
show_help() {
    echo "PipeWire 音頻服務管理腳本"
    echo
    echo "用法: $0 [選項]"
    echo
    echo "選項:"
    echo "  restart, -r    重啟 PipeWire 服務（默認）"
    echo "  start          啟動 PipeWire 服務"
    echo "  stop           停止 PipeWire 服務"
    echo "  status, -s     顯示服務狀態"
    echo "  help, -h       顯示此幫助信息"
    echo
    echo "範例:"
    echo "  $0              # 重啟服務"
    echo "  $0 restart      # 重啟服務"
    echo "  $0 status       # 查看狀態"
    echo "  $0 stop         # 停止服務"
    echo "  $0 start        # 啟動服務"
}

# 主函數
main() {
    case "${1:-help}" in
        restart|-r)
            restart_services
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        status|-s)
            show_status
            ;;
        help|-h)
            show_help
            ;;
        *)
            log_error "未知選項: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# 執行主函數
main "$@"
