#!/bin/bash

set -e  # 遇到錯誤時停止

echo "=========================="
echo "🕒 0. 同步 NTP 時間"
echo "=========================="
sudo timedatectl set-ntp true

echo "=========================="
echo "🚀 1. 更新官方套件庫 (pacman -Syu)"
echo "=========================="
sudo pacman -Syu --noconfirm

echo "=========================="
echo "🌐 2. 更新 AUR 套件（如果有 yay）"
echo "=========================="
if command -v yay &>/dev/null; then
    yay -Syu --noconfirm --removemake --answerdiff N --answerclean N
else
    echo "⚠️ 未安裝 yay，跳過 AUR 更新"
fi

echo "=========================="
echo "📦 3. 更新 Flatpak 應用程式"
echo "=========================="
if command -v flatpak &>/dev/null; then
    flatpak update -y
else
    echo "⚠️ Flatpak 未安裝，跳過此步驟"
fi

echo "=========================="
echo "🗑 4. 清理孤立的套件 (pacman -Qdtq)"
echo "=========================="
if pacman -Qdtq &>/dev/null; then
    sudo pacman -Rns --noconfirm $(pacman -Qdtq)
else
    echo "✅ 沒有孤立的套件需要移除"
fi

echo "=========================="
echo "🛠 5. 檢查並修復系統檔案 (pacman -Qkk)"
echo "=========================="
echo "⚙️ 檢查系統檔案完整性..."

if sudo pacman -Qkk 2>&1 | grep -q -v "0 個檔案經修改\|0 altered files\|0 missing files"; then
    echo "⚠️ 發現檔案問題，詳細信息："
    sudo pacman -Qkk 2>&1 | grep -v "0 個檔案經修改\|0 altered files\|0 missing files"
else
    echo "✅ 系統檔案檢查正常"
fi

echo "=========================="
echo "🗑 6. 清理 Pacman 緩存 (paccache -r)"
echo "=========================="
sudo paccache -r -k2  # 僅保留最新 2 個版本

echo "=========================="
echo "🔧 7. 重新編譯 DKMS 模組（如果有）"
echo "=========================="
if command -v dkms &>/dev/null; then
    KERNEL_VERSION=$(uname -r)
    HEADER_PATH="/usr/lib/modules/$KERNEL_VERSION/build"
    if [ -d "$HEADER_PATH" ]; then
        echo "⚙️ 嘗試重新編譯 DKMS 模組..."
        set +e  # 暫時關閉遇錯即停
        if ! sudo dkms autoinstall; then
            echo "❌ DKMS 編譯失敗，但腳本將繼續執行"
        else
            echo "✅ DKMS 模組編譯成功"
        fi
        set -e  # 重新開啟遇錯即停
    else
        echo "⚠️ 找不到 kernel headers：$KERNEL_VERSION"
        echo "👉 請安裝對應的 kernel headers，例如：sudo pacman -S linux-headers"
    fi
else
    echo "⚠️ DKMS 未安裝，跳過此步驟"
fi

echo "=========================="
echo "✅ 系統更新與最佳化完成！請重新開機以應用變更"
echo "=========================="

read -p "是否現在重新開機？(y/n): " -n 1 -r confirm
echo  # 換行
if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "🔄 3秒後重新開機..."
    sleep 3
    sudo reboot
else
    echo "✅ 更新完成，請記得稍後手動重新開機"
fi
