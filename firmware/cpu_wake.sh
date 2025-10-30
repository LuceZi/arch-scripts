#!/bin/bash
echo "=== $(date) ===" >> ~/cpu_debug.log
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference >> ~/cpu_debug.log
cat /sys/devices/system/cpu/intel_pstate/max_perf_pct >> ~/cpu_debug.log
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq >> ~/cpu_debug.log
