#!/bin/bash
if [ "$1" = "post" ]; then
    # Resume 後等 EC 穩定
    sleep 1
    
    # 對每個 CPU 重寫 HWP_REQUEST
    for cpu in {0..7}; do
        # P-cores: Min=8, Max=50, Desired=0 (auto), EPP=128 (balance)
        wrmsr -p $cpu 0x774 0x8032 2>/dev/null || true
    done
    
    # 確保 intel_pstate 重新讀取
    echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct
    echo 8 > /sys/devices/system/cpu/intel_pstate/min_perf_pct
fi
