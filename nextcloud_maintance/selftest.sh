#!/bin/bash

LOGFILE="/var/log/ncp-health.log"
NC_PATH="/var/www/nextcloud"
PHP_BIN="/usr/bin/php"
USER="www-data"

echo "=== Nextcloud Health Check - $(date) ===" >> "$LOGFILE"

# 1. Apache2 檢查
echo "[Apache2 Status]" >> "$LOGFILE"
systemctl is-active apache2 >> "$LOGFILE" 2>&1

# 2. PHP 模組與版本
echo "[PHP Version]" >> "$LOGFILE"
$PHP_BIN -v | head -n 1 >> "$LOGFILE"

echo "[PHP Modules]" >> "$LOGFILE"
$PHP_BIN -m | grep -E 'gd|xml|zip|bz2|intl|mbstring|curl|imagick|sqlite3|mysql|pgsql' >> "$LOGFILE"

# 3. 資料庫狀態（以 MariaDB 為例）
echo "[MariaDB Status]" >> "$LOGFILE"
systemctl is-active mariadb >> "$LOGFILE" 2>&1

# 4. Nextcloud OCC 狀態
echo "[Nextcloud OCC Status]" >> "$LOGFILE"
sudo -u $USER $PHP_BIN "$NC_PATH/occ" status >> "$LOGFILE" 2>&1

# 5. notify_push / mcp 狀態（假設是 systemd 服務）
echo "[notify_push / mcp Status]" >> "$LOGFILE"
systemctl is-active notify_push >> "$LOGFILE" 2>&1 || echo "notify_push not found" >> "$LOGFILE"
systemctl is-active mcp >> "$LOGFILE" 2>&1 || echo "mcp not found" >> "$LOGFILE"

# 6. 權限檢查
echo "[Nextcloud Directory Permission Check]" >> "$LOGFILE"
stat -c "%U:%G %a %n" "$NC_PATH/config/config.php" >> "$LOGFILE" 2>/dev/null

# 7. 磁碟空間 / 記憶體 / CPU
echo "[Disk Usage]" >> "$LOGFILE"
df -h / | tail -1 >> "$LOGFILE"

echo "[Memory Usage]" >> "$LOGFILE"
free -h >> "$LOGFILE"

echo "[CPU Load]" >> "$LOGFILE"
uptime >> "$LOGFILE"

echo "=== End ===" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# 自檢完成後，來一段人類語言確認
if [ $? -eq 0 ]; then
    echo "✅ 自檢完成於 $(date '+%Y-%m-%d %H:%M')，一切看起來正常。自檢結果在 ""$LOGFILE"""
else
    echo "⚠ 自檢在 $(date '+%Y-%m-%d %H:%M') 發生錯誤，請檢查上方 log。" | tee -a "$LOGFILE"
fi
