"""======================================================
This script displays the features you added
on Raspberry Pi and formats the output by cowsay.

Program Name: Raspberry Pi start script
Version: 1.1
Author: Luce (Xinyu) and GPT
Creation Date: 2024/12/17
Last Modified: 2024/12/25
License: MIT License

Dependencies:
- cowsay
- subprocess
- os
- datetime

Usage:
1. Ensure cowsay is installed on your Raspberry Pi.
2. Run this script to see a humorous output infomation by cowsay.
======================================================"""
import os
import subprocess
import inspect
from datetime import datetime

USER_NAME = "Luce"

def call_neofetch():
    try:
        os.system("fastfetch")
    except Exception as e:
        func_name = inspect.currentframe().f_code.co_name
        raise RuntimeError(f"{func_name} 發生錯誤: \n{str(e)}")

def call_cowsay():
    def _get_cpu_temperature():
        try:
            # 打開檔案，讀取 CPU 溫度
            with open("/sys/class/thermal/thermal_zone0/temp", "r") as temp_file:
                temp_data = temp_file.read()
            # 將數據轉換成攝氏溫度 (千分之一度)
            temp_celsius = int(temp_data) / 1000.0
            return temp_celsius
        except Exception as e:
            func_name = inspect.currentframe().f_code.co_name
            raise RuntimeError(f"{func_name} 發生錯誤: \n{str(e)}")
    try:
        # 取得目前時間
        current_date = datetime.now().strftime("%Y-%m-%d")
        current_time = datetime.now().strftime("%H:%M:%S")
        #取得CPU溫度
        cpu_temp = _get_cpu_temperature()
        cpu_temp_message = f"CPU Temp: {cpu_temp:.1f} °C"
        
        # cowsay 消息
        image = "unipony-smaller"
        message_line1 = f"Date: {current_date}  {current_time}"
        message_line2 = f"{cpu_temp_message}"
        message_line3 = f"Hello {USER_NAME}!  つ◕_◕ つ"
        #message = f"{message_line1}\n {message_line2}\n {message_line3}"
        message = f"Hello {USER_NAME}! Have a nice day~"

        # 使用 cowsay, library deriction /usr/share/cowsay/cows/
        subprocess.run(['cowsay', '-f', image, message], check=True)
    except Exception as e:
        func_name = inspect.currentframe().f_code.co_name
        raise RuntimeError(f"{func_name} 發生錯誤: \n{str(e)}")

def start_program():
    #call_neofetch()
    call_cowsay()

if __name__ == "__main__":
    try:
        print(f"python startup script at {os.path.abspath(__file__)}\n ")
        start_program()
    except Exception as e:
        print(f"QAQ: {e}\nLuce! fix this at {os.path.abspath(__file__)}\n ")
    finally:
        print("python startup script end!")
