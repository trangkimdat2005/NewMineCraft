@echo off
title Minecraft Server with Auto Backup

:: Đặt mã hóa UTF-8 cho CMD
chcp 65001

:: Chạy auto backup trong tiến trình riêng
start "Backup Auto" cmd /c call "%~dp0backup\backup.bat"

:: Chạy Minecraft server với encoding UTF-8
java -Dfile.encoding=UTF-8 -Xms2G -Xmx2G -jar server.jar nogui

:: Sau khi server dừng
echo.
echo >>> Đang tắt backup...

for /f "tokens=2" %%i in ('tasklist /v ^| findstr /i "auto_backup.bat"') do (
    taskkill /PID %%i /F
)

pause