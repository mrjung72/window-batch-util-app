@echo off
setlocal enabledelayedexpansion

REM === ���� Ȯ�� ===
if "%~1"=="" (
    echo [ERROR] CSV ���� ��θ� ���ڷ� �Է��ϼ���.
    echo ��: check_telnet.bat C:\path\to\servers.csv
    exit /b 1
)

set "CSV_FILE=%~1"

REM === CSV ���� ���� Ȯ�� ===
if not exist "%CSV_FILE%" (
    echo [ERROR] ������ CSV ������ �������� �ʽ��ϴ�: %CSV_FILE%
    exit /b 1
)

REM === MariaDB ���� ���� ===
set DB_HOST=localhost
set DB_USER=guest
set DB_PASS=9999
set DB_NAME=etcdb

REM === ���� PC�� IP �ּ� �������� ===
for /f "tokens=2 delims=:" %%I in ('ipconfig ^| findstr /c:"IPv4 �ּ�" /c:"IPv4 Address"') do (
    for /f "delims= " %%J in ("%%I") do set "MY_IP=%%J"
)
echo [INFO] ���� PC�� IP �ּ�: %MY_IP%
echo [INFO] CSV ���� ��� : %CSV_FILE%

REM === CSV ���� �б� �� telnet �׽�Ʈ ===
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
        echo [SUCCESS] !IP!:!PORT! !HOSTNAME! �����
    ) else (
        set STATUS=fail
        echo [FAIL] !IP!:!PORT! !HOSTNAME! ���� ����
        echo [ERROR MSG] !ERRMSG!
    )

    REM DB�� 1�Ǿ� ��� ����
    mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% -e ^
    "INSERT INTO %DB_NAME%.servers_connect_his (user_pc_ip, server_ip, port, connect_method, return_code, return_desc) VALUES ('%MY_IP%', '!IP!', !PORT!, 'telnet', '!STATUS!', '!ERRMSG!');"
)

echo.
echo [INFO] ��� ���� ���� �� DB �Է� �Ϸ�
endlocal
pause
