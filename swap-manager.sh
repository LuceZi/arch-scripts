# 即時監控
watch -n 1 'free -h && cat /proc/swaps'

# 查看哪些程序在使用swap
for pid in /proc/[0-9]*; do 
    if [ -r "$pid/smaps" ]; then
        swap=$(awk '/^Swap:/ {sum += $2} END {print sum}' "$pid/smaps" 2>/dev/null)
        if [ "$swap" -gt 0 ] 2>/dev/null; then
            echo "PID: $(basename $pid), Swap: ${swap}kB"
        fi
    fi
done