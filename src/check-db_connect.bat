@echo off
setlocal ENABLEDELAYEDEXPANSION

REM === �Է� ���� Ȯ�� ===
if "%~1"=="" (
    echo [����] CSV ���� ��ΰ� �ʿ��մϴ�.
    echo ex) check-db_connect.bat C:\path\to\servers.csv {����DB_���Ӱ���ID} {����DB_���Ӱ���Password}
    exit /b 1
)
if "%~2"=="" (
    echo [����] ���� MSSQL ���� ID�� �ʿ��մϴ�.
    echo ex) check-db_connect.bat C:\path\to\servers.csv {����DB_���Ӱ���ID} {����DB_���Ӱ���Password}
    exit /b 1
)
if "%~3"=="" (
    echo [����] ���� MSSQL ���� Password�� �ʿ��մϴ�.
    echo ex) check-db_connect.bat C:\path\to\servers.csv {����DB_���Ӱ���ID} {����DB_���Ӱ���Password}
    exit /b 1
)

set "CSV_FILE=%~1"
set "TARGET_DB_USER=%~2"
set "TARGET_DB_PASS=%~3"
set DB_HOST=localhost
set DB_USER=guest
set DB_PASS=9999
set DB_NAME=etcdb

REM === CSV ���� ���� Ȯ�� ===
if not exist "%CSV_FILE%" (
    echo [ERROR] ������ CSV ������ �������� �ʽ��ϴ�: %CSV_FILE%
    exit /b 1
)

REM === ���� PC IP �������� ===
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=* delims= " %%B in ("%%A") do (
        set "MY_IP=%%B"
    )
)

echo [INFO] ���� PC�� IP �ּ�: %MY_IP%
echo [INFO] CSV ���� ��� : %CSV_FILE%

REM === CSV �б� ===
for /f "tokens=1,2,3 delims=," %%A in (%CSV_FILE%) do (
    set "TARGET_IP=%%A"
    set "TARGET_PORT=%%B"
    set "TARGET_DB=%%C"

    set "STATUS=success"
    set "ERRMSG="

    REM === SQLCMD ���� �׽�Ʈ ===
    sqlcmd -S !TARGET_IP!,!TARGET_PORT! -d !TARGET_DB! -U %TARGET_DB_USER% -P %TARGET_DB_PASS% -Q "SELECT 1" > nul 2>err.txt

    if !errorlevel! NEQ 0 (
        set "STATUS=fail"
        for /f "delims=" %%E in (err.txt) do (
            set "ERRMSG=%%E"
        )
    )

    del err.txt > nul 2>&1

    REM DB�� 1�Ǿ� ��� ����
    mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% -e ^
    "INSERT INTO %DB_NAME%.servers_connect_his (user_pc_ip, server_ip, port, connect_method, db_name, db_user, return_code, return_desc) VALUES ('%MY_IP%', '!TARGET_IP!', !TARGET_PORT!, 'db_connect', '!TARGET_DB!','%DB_USER%', '!STATUS!', '!ERRMSG!');"

    echo [���] !TARGET_IP!:!TARGET_PORT! => !STATUS!
)

echo.
echo [INFO] DB���� ���� �Ϸ�
endlocal
pause
