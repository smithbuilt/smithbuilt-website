@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM  Smithbuilt - Site Upload Script
REM  Uploads local Public_HTML folder to iFastNet server
REM  via FTPS (Explicit TLS) using curl (built into Windows 10/11)
REM
REM  Only uploads files modified since the last successful upload
REM  (tracked via upload-timestamp.txt - delete it to force full upload).
REM
REM  Usage:
REM    upload.bat            (dry run - lists files that would upload)
REM    upload.bat live       (actually uploads)
REM ============================================================

set "LOCAL_DIR=%~dp0Public_HTML"
set "REMOTE_DIR=/"
set "CRED_FILE=%~dp0ftp-credentials.txt"
set "LOG_FILE=%~dp0upload-log.txt"
set "TIMESTAMP_FILE=%~dp0upload-timestamp.txt"
set "TEMP_LIST=%TEMP%\smithbuilt-upload-list.txt"

set "SKIP_PATTERNS=Thumbs.db .DS_Store desktop.ini"

REM --- Load credentials ---
if not exist "%CRED_FILE%" (
    echo ERROR: Credentials file not found at %CRED_FILE%
    echo Please create it with FTP_HOST, FTP_USER, FTP_PASS on separate lines.
    pause
    exit /b 1
)
for /f "usebackq tokens=1,* delims==" %%A in ("%CRED_FILE%") do set "%%A=%%B"

if not defined FTP_HOST goto missing_creds
if not defined FTP_USER goto missing_creds
if not defined FTP_PASS goto missing_creds
goto creds_ok

:missing_creds
echo ERROR: %CRED_FILE% must contain FTP_HOST, FTP_USER, and FTP_PASS lines.
pause
exit /b 1

:creds_ok

REM --- Determine mode ---
set "MODE=%~1"
if "!MODE!"=="" set "MODE=dryrun"

if /i "!MODE!"=="dryrun" goto do_dryrun
if /i "!MODE!"=="live" goto do_live

echo ERROR: Unknown mode "!MODE!"
echo Usage:
echo   upload.bat            (dry run, lists files that would upload)
echo   upload.bat live       (actually uploads)
pause
exit /b 1

:do_dryrun
set "DRY=1"
echo.
echo ============================================================
echo   DRY RUN MODE - lists files; nothing is uploaded
echo   To run for real: upload.bat live
echo ============================================================
echo.
goto build_list

:do_live
set "DRY="
echo.
echo ============================================================
echo   LIVE MODE - files WILL be uploaded to !FTP_HOST!
echo ============================================================
echo.
choice /M "Are you sure you want to upload for real"
if errorlevel 2 (
    echo Cancelled.
    pause
    exit /b 0
)
goto build_list

REM ============================================================
REM Build the list of files to consider (newer than timestamp,
REM or all files if no timestamp exists).
REM Uses PowerShell with foreach (no pipes) to avoid cmd parsing issues.
REM ============================================================
:build_list
echo.
> "%LOG_FILE%" echo Smithbuilt FTP upload log - %date% %time%

if exist "%TIMESTAMP_FILE%" goto build_diff
goto build_full

:build_full
echo First run (no upload-timestamp.txt) - listing all files ...
powershell -NoProfile -Command "foreach ($f in (Get-ChildItem -Recurse -File -Path '%LOCAL_DIR%')) { $f.FullName }" > "%TEMP_LIST%"
goto count_list

:build_diff
echo Comparing local files against last-upload time ...
powershell -NoProfile -Command "$ts = (Get-Item '%TIMESTAMP_FILE%').LastWriteTime; foreach ($f in (Get-ChildItem -Recurse -File -Path '%LOCAL_DIR%')) { if ($f.LastWriteTime -gt $ts) { $f.FullName } }" > "%TEMP_LIST%"
goto count_list

:count_list
set /a TO_PROCESS=0
for /f "usebackq delims=" %%F in ("%TEMP_LIST%") do set /a TO_PROCESS+=1

if !TO_PROCESS! EQU 0 goto nothing_to_do

echo !TO_PROCESS! file(s) to consider.
echo.

set /a UPLOADED=0
set /a SKIPPED=0
set /a FAILED=0

REM Process each file via subroutine call (avoids deep nesting in for-loop)
for /f "usebackq delims=" %%F in ("%TEMP_LIST%") do call :process_one "%%F"

if exist "%TEMP_LIST%" del "%TEMP_LIST%"

REM Update timestamp only on a successful live run
if defined DRY goto show_summary
if "!FAILED!"=="0" echo. > "%TIMESTAMP_FILE%"
goto show_summary

REM ============================================================
REM Subroutine: handle a single file
REM   %1 = full path to local file
REM ============================================================
:process_one
set "FULLPATH=%~1"
set "FILENAME=%~nx1"
set "RELPATH=!FULLPATH:%LOCAL_DIR%\=!"
set "RELPATH_FWD=!RELPATH:\=/!"

set "SKIP=0"
for %%S in (%SKIP_PATTERNS%) do if /i "!FILENAME!"=="%%S" set "SKIP=1"

if "!SKIP!"=="1" goto sub_skip
if defined DRY goto sub_dry
goto sub_upload

:sub_skip
echo SKIP   !RELPATH_FWD!
set /a SKIPPED+=1
goto :eof

:sub_dry
echo WOULD  !RELPATH_FWD!
set /a UPLOADED+=1
goto :eof

:sub_upload
echo UPLOAD !RELPATH_FWD!
set "RELPATH_URL=!RELPATH_FWD: =%%20!"
REM -k skips cert hostname verification (shared hosting often uses generic
REM certs that don't match per-account FTP hostnames). TLS is still active.
curl -k --ssl-reqd --ftp-create-dirs --silent --show-error -u "!FTP_USER!:!FTP_PASS!" --upload-file "!FULLPATH!" "ftp://!FTP_HOST!/!RELPATH_URL!" >> "%LOG_FILE%" 2>&1
if errorlevel 1 goto sub_upload_failed
set /a UPLOADED+=1
goto :eof

:sub_upload_failed
echo    FAILED - see upload-log.txt
set /a FAILED+=1
goto :eof

REM ============================================================
:nothing_to_do
echo.
echo ============================================================
echo   Nothing changed since last upload. Done.
echo ============================================================
echo.
if exist "%TEMP_LIST%" del "%TEMP_LIST%"
pause
exit /b 0

:show_summary
echo.
echo ============================================================
if defined DRY (
    echo   Dry run: !UPLOADED! would upload, !SKIPPED! skipped
    goto end_summary
)
if "!FAILED!"=="0" (
    echo   SUCCESS - !UPLOADED! uploaded, !SKIPPED! skipped
    echo   Timestamp updated: only changed files upload next time
) else (
    echo   PARTIAL - !UPLOADED! uploaded, !FAILED! failed, !SKIPPED! skipped
    echo   Timestamp NOT updated - re-run will retry failures
    echo   See upload-log.txt for details
)
:end_summary
echo ============================================================
echo.
pause
exit /b !FAILED!
