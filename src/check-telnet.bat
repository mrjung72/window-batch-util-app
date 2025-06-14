@echo off
setlocal enabledelayedexpansion

REM === 인자 확인 ===
if "%~1"=="" (
    echo [ERROR] CSV 파일 경로를 인자로 입력하세요.
    echo 예: check_telnet.bat C:\path\to\servers.csv
    exit /b 1
)

set "CSV_FILE=%~1"

REM === CSV 파일 존재 확인 ===
if not exist "%CSV_FILE%" (
    echo [ERROR] 지정한 CSV 파일이 존재하지 않습니다: %CSV_FILE%
    exit /b 1
)

REM === MariaDB 접속 정보 ===
set DB_HOST=localhost
set DB_USER=guest
set DB_PASS=9999
set DB_NAME=etcdb

REM === 현재 PC의 IP 주소 가져오기 ===
for /f "tokens=2 delims=:" %%I in ('ipconfig ^| findstr /c:"IPv4 주소" /c:"IPv4 Address"') do (
    for /f "delims= " %%J in ("%%I") do set "MY_IP=%%J"
)
echo [INFO] 현재 PC의 IP 주소: %MY_IP%
echo [INFO] CSV 파일 경로 : %CSV_FILE%

REM === CSV 파일 읽기 및 telnet 테스트 ===
for /f "skip=1 tokens=1,2,3 delims=," %%A in (%CSV_FILE%) do (
    set "IP=%%A"
    set "PORT=%%B"
    set "HOSTNAME=%%C"
    set ERRMSG=
    set STATUS=

    echo.
    echo [INFO] Checking !IP!:!PORT! !HOSTNAME! ...

    for /f "delims=" %%X in ('powershell -Command "try { $r=Test-NetConnection -ComputerName '!IP!' -Port !PORT! -ErrorAction Stop; if ($r.TcpTestSucceeded) { exit 0 } else { Write-Error 'TCP failed'; exit 1 } } catch { Write-Output $_.Exception.Message; exit 2 }" 2^>^&1') do (
        set "ERRMSG=%%X"
    )

    if !errorlevel! EQU 0 (
        set STATUS=success
        set "ERRMSG="
        echo [SUCCESS] !IP!:!PORT! !HOSTNAME! 연결됨
    ) else (
        set STATUS=fail
        echo [FAIL] !IP!:!PORT! !HOSTNAME! 연결 실패
        echo [ERROR MSG] !ERRMSG!
    )

    REM DB에 1건씩 즉시 삽입
    mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% -e ^
    "INSERT INTO %DB_NAME%.servers_connect_his (user_pc_ip, server_ip, port, connect_method, return_code, return_desc) VALUES ('%MY_IP%', '!IP!', !PORT!, 'telnet', '!STATUS!', '!ERRMSG!');"
)

echo.
echo [INFO] 모든 서버 점검 및 DB 입력 완료
endlocal
pause
