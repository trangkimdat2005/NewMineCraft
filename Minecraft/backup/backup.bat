@echo off
title Auto Backup (ZIP + Check Changed + Safe Copy)
setlocal enabledelayedexpansion

set maxBackups=1
set backupRoot=backup
set worldDir=world
set tempWorldDir=world_temp_copy
set lastHashFile=last_hash.txt

:: Tạo thư mục backup nếu chưa có
if not exist "%backupRoot%" mkdir "%backupRoot%"

:loop
:: Tạo timestamp dạng yyyy-MM-dd_HH-mm
for /f %%a in ('wmic os get LocalDateTime ^| find "."') do set datetime=%%a
set datetime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%
set zipName=world_%datetime%.zip
set zipPath=%backupRoot%\%zipName%

:: Kiểm tra file level.dat tồn tại
if not exist "%worldDir%\level.dat" (
    echo [WARN] Không tìm thấy %worldDir%\level.dat. Bỏ qua backup.
    timeout /t 300 >nul
    goto loop
)

:: Lấy hash của level.dat
for /f "skip=1 tokens=1" %%h in ('certutil -hashfile "%worldDir%\level.dat" SHA256 ^| find /v "hash of" ^| find /v "CertUtil"') do (
    set "currentHash=%%h"
    goto :hashDone
)
:hashDone

:: So sánh hash để kiểm tra thay đổi
set changed=true
if exist "%lastHashFile%" (
    for /f %%h in (%lastHashFile%) do (
        if "%%h"=="%currentHash%" set changed=false
    )
)

if "%changed%"=="true" (
    echo [INFO] Thế giới đã thay đổi. Đang sao chép và nén...

    :: Xoá thư mục tạm nếu tồn tại
    if exist "%tempWorldDir%" rd /s /q "%tempWorldDir%"

    :: Dùng robocopy để sao chép an toàn (retry nếu file bị khóa)
    robocopy "%worldDir%" "%tempWorldDir%" /MIR /R:5 /W:2 >nul

    :: Nén bản sao thành .zip
    powershell -Command "Compress-Archive -Path '%tempWorldDir%\*' -DestinationPath '%zipPath%'"

    :: Ghi lại hash mới
    echo %currentHash% > %lastHashFile%

    :: Xoá bản sao tạm
    rd /s /q "%tempWorldDir%"

) else (
    echo [INFO] Không có thay đổi. Bỏ qua backup.
)

:: Xoá backup cũ nếu vượt quá giới hạn
set count=0
for /f %%i in ('dir /b /a:-d /o:n "%backupRoot%\world_*.zip"') do (
    set /a count+=1
    set "file[!count!]=%%i"
)

if !count! gtr %maxBackups% (
    set /a toDelete=!count! - %maxBackups%
    for /l %%j in (1,1,!toDelete!) do (
        echo [INFO] Xoá bản cũ: !file[%%j]!
        del "%backupRoot%\!file[%%j]!"
    )
)

timeout /t 300 >nul
goto loop