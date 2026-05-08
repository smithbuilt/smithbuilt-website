@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM  Smithbuilt - Site Upload Script
REM  Uploads local Public_HTML folder to iFastNet server
REM  via FTPS (Explicit TLS)
REM
REM  Requires winscp.com to be on the system PATH.
REM ============================================================

REM --- Configuration ---
REM   FTP_HOST, FTP_USER, FTP_PASS are loaded from ftp-credentials.txt
REM   (gitignored) so this script can be safely committed.
set "LOCAL_DIR=%~dp0Public_HTML"
set "REMOTE_DIR=/"
set "CRED_FILE=%~dp0ftp-credentials.txt"
set "LOG_FILE=%~dp0upload-log.txt"

REM --- Files/folders that must NEVER be uploaded ---
REM   ftp-credentials.txt = contains your password
REM   upload.bat / upload.sh = the deploy script itself
REM   upload-log.txt = WinSCP log file
REM   .gitignore / .git = Git metadata
REM   *.bak / *.tmp = editor backup files
REM   Thumbs.db / .DS_Store = OS junk
set "EXCLUDE=| ftp-credentials.txt; upload.bat; upload.sh; upload-log.txt; .gitignore; .git/; *.bak; *.tmp; Thumbs.db; .DS_Store; desktop.ini"

REM --- Read host, user, password from credentials file ---
REM   Expected format (one key=value per line):
REM     FTP_HOST=ftp.example.com
REM     FTP_USER=username@example.com
REM     FTP_PASS=yourpassword
if not exist "%CRED_FILE%" (
    echo ERROR: Credentials file not found at %CRED_FILE%
    echo Please create it with FTP_HOST, FTP_USER, FTP_PASS on separate lines.
    pause
    exit /b 1
)
for /f "usebackq tokens=1,* delims==" %%A in ("%CRED_FILE%") do set "%%A=%%B"

if not defined FTP_HOST goto :missing_creds
if not defined FTP_USER goto :missing_creds
if not defined FTP_PASS goto :missing_creds
goto :creds_ok

:missing_creds
echo ERROR: %CRED_FILE% must contain FTP_HOST, FTP_USER, and FTP_PASS lines.
pause
exit /b 1

:creds_ok

REM --- Determine mode based on first argument ---
set "MODE=%~1"
if "!MODE!"=="" set "MODE=dryrun"

if /i "!MODE!"=="dryrun" goto :do_dryrun
if /i "!MODE!"=="live" goto :do_live

echo ERROR: Unknown mode "!MODE!"
echo Usage:
echo   upload.bat            (dry run, shows what would change)
echo   upload.bat live       (actually uploads)
pause
exit /b 1

:do_dryrun
set "PREVIEW_FLAG=-preview"
echo.
echo ============================================================
echo   DRY RUN MODE - No files will actually be uploaded
echo   To run for real, use: upload.bat live
echo ============================================================
echo.
goto :run_winscp

:do_live
set "PREVIEW_FLAG="
echo.
echo ============================================================
echo   LIVE MODE - Files WILL be uploaded to the server
echo ============================================================
echo.
choice /M "Are you sure you want to upload for real"
if errorlevel 2 (
    echo Cancelled.
    pause
    exit /b 0
)
goto :run_winscp

:run_winscp
echo Connecting to !FTP_HOST! ...
echo.

winscp.com /log="%LOG_FILE%" /loglevel=1 /command ^
    "open ftpes://!FTP_USER!:!FTP_PASS!@!FTP_HOST!/ -explicit -passive=on" ^
    "synchronize remote !PREVIEW_FLAG! -delete=off -criteria=time -filemask=""!EXCLUDE!"" ""!LOCAL_DIR!"" ""!REMOTE_DIR!""" ^
    "exit"

set "RESULT=!ERRORLEVEL!"

echo.
if "!RESULT!"=="0" (
    echo ============================================================
    echo   SUCCESS - See upload-log.txt for details
    echo ============================================================
) else (
    echo ============================================================
    echo   FAILED with code !RESULT! - See upload-log.txt for details
    echo ============================================================
)

echo.
pause
exit /b !RESULT!