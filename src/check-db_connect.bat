@echo off
setlocal ENABLEDELAYEDEXPANSION

REM === 입력 인자 확인 ===
if "%~1"=="" (
    echo [오류] CSV 파일 경로가 필요합니다.
    echo ex) check-db_connect.bat C:\path\to\servers.csv {원격DB_접속계정ID} {원격DB_접속계정Password}
    exit /b 1
)
if "%~2"=="" (
    echo [오류] 원격 MSSQL 접속 ID가 필요합니다.
    echo ex) check-db_connect.bat C:\path\to\servers.csv {원격DB_접속계정ID} {원격DB_접속계정Password}
    exit /b 1
)
if "%~3"=="" (
    echo [오류] 원격 MSSQL 접속 Password가 필요합니다.
    echo ex) check-db_connect.bat C:\path\to\servers.csv {원격DB_접속계정ID} {원격DB_접속계정Password}
    exit /b 1
)

set "CSV_FILE=%~1"
set "TARGET_DB_USER=%~2"
set "TARGET_DB_PASS=%~3"
set DB_HOST=localhost
set DB_USER=guest
set DB_PASS=9999
set DB_NAME=etcdb

REM === CSV 파일 존재 확인 ===
if not exist "%CSV_FILE%" (
    echo [ERROR] 지정한 CSV 파일이 존재하지 않습니다: %CSV_FILE%
    exit /b 1
)

REM === 현재 PC IP 가져오기 ===
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=* delims= " %%B in ("%%A") do (
        set "MY_IP=%%B"
    )
)

echo [INFO] 현재 PC의 IP 주소: %MY_IP%
echo [INFO] CSV 파일 경로 : %CSV_FILE%

REM === CSV 읽기 ===
for /f "tokens=1,2,3 delims=," %%A in (%CSV_FILE%) do (
    set "TARGET_IP=%%A"
    set "TARGET_PORT=%%B"
    set "TARGET_DB=%%C"

    set "STATUS=success"
    set "ERRMSG="

    REM === SQLCMD 접속 테스트 ===
    sqlcmd -S !TARGET_IP!,!TARGET_PORT! -d !TARGET_DB! -U %TARGET_DB_USER% -P %TARGET_DB_PASS% -Q "SELECT 1" > nul 2>err.txt

    if !errorlevel! NEQ 0 (
        set "STATUS=fail"
        for /f "delims=" %%E in (err.txt) do (
            set "ERRMSG=%%E"
        )
    )

    del err.txt > nul 2>&1

    REM DB에 1건씩 즉시 삽입
    mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% -e ^
    "INSERT INTO %DB_NAME%.servers_connect_his (user_pc_ip, server_ip, port, connect_method, db_name, db_user, return_code, return_desc) VALUES ('%MY_IP%', '!TARGET_IP!', !TARGET_PORT!, 'db_connect', '!TARGET_DB!','%DB_USER%', '!STATUS!', '!ERRMSG!');"

    echo [결과] !TARGET_IP!:!TARGET_PORT! => !STATUS!
)

echo.
echo [INFO] DB서버 점검 완료
endlocal
pause
