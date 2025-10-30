#!/bin/bash
# 獲取所有已安裝的 Flatpak 應用
for app in $(flatpak list --app --columns=application); do
    echo "Setting up fonts for $app"
    
    # 創建應用程式專用字體配置目錄
    mkdir -p ~/.var/app/$app/config/fontconfig/
    
    # 複製字體配置
    cp ~/.config/fontconfig/fonts.conf ~/.var/app/$app/config/fontconfig/
    
    # 設置環境變數
    flatpak override --user --env=QT_FONTCONFIG=1 $app
    flatpak override --user --env=GTK_FONTCONFIG=1 $app
done
