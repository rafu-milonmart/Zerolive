@echo off
rem ============================================================
rem  ZeroLive Installer (batch)
rem  Installs ZeroLive to C:\Zero_live (or custom path)
rem  No .exe needed - just this script + curl/tar built into Win10+
rem ============================================================
setlocal enabledelayedexpansion
title ZeroLive Installer
cd /d "%~dp0"

set "PY_VER=3.13.5"
set "REPO=https://github.com/rafu-milonmart/Zerolive"
set "REPO_API=https://api.github.com/repos/rafu-milonmart/Zerolive"
set "PY_URL=https://www.python.org/ftp/python/!PY_VER!/python-!PY_VER!-embed-amd64.zip"
set "PIP_URL=https://bootstrap.pypa.io/get-pip.py"

echo ============================================
echo   ZeroLive - Installer
echo ============================================
echo.
echo   This will install ZeroLive on this PC.
echo   Python %PY_VER% (embedded) is downloaded and bundled locally.
echo.

set "DEST=C:\Zero_live"
set /p DEST_INPUT="Install directory [%DEST%]: "
if not "!DEST_INPUT!"=="" set "DEST=!DEST_INPUT!"
if "!DEST:~-1!"=="\" set "DEST=!DEST:~0,-1!"

echo.
echo Installing to: !DEST!
echo.

rem ---- 1. Python ----------------------------------------------------
echo [1/7] Downloading Python !PY_VER!...
if exist "!DEST!\python\python.exe" goto PY_EXISTS
mkdir "%TEMP%\zerolive_install" >nul 2>&1
curl.exe -L -sS -o "%TEMP%\zerolive_install\python.zip" "!PY_URL!"
if errorlevel 1 ( echo [ERROR] Python download failed. Check internet. & pause & exit /b 1 )

echo [2/7] Extracting Python...
mkdir "!DEST!" >nul 2>&1
mkdir "!DEST!\python" >nul 2>&1
tar.exe -xf "%TEMP%\zerolive_install\python.zip" -C "!DEST!\python"
if errorlevel 1 ( echo [ERROR] Extract failed. & pause & exit /b 1 )

for %%F in ("!DEST!\python\python*._pth") do (
    powershell -NoProfile -Command "$p='%%F'; (Get-Content -LiteralPath $p -Raw) -replace '#import site','import site' | Set-Content -LiteralPath $p -NoNewline" >nul 2>&1
)

:PY_EXISTS
set "PYEXE=!DEST!\python\python.exe"
if not exist "!PYEXE!" ( echo [ERROR] Python missing. & pause & exit /b 1 )
echo       Python OK.

rem ---- 2. pip -------------------------------------------------------
echo [3/7] Setting up pip...
if not exist "!DEST!\python\Scripts\pip.exe" (
    curl.exe -L -sS -o "%TEMP%\zerolive_install\get-pip.py" "!PIP_URL!"
    "!PYEXE!" "%TEMP%\zerolive_install\get-pip.py" --no-setuptools --no-wheel >nul 2>&1
)
if not exist "!DEST!\python\Scripts\pip.exe" ( echo [WARN] pip not ready, continuing anyway... )

rem ---- 3. App files ---------------------------------------------------
echo [4/7] Getting ZeroLive files...
if exist "%~dp0app.py" (
    echo       Using local source folder.
    set "SRC=%~dp0"
    set "SRC=!SRC:~0,-1!"
    robocopy "!SRC!" "!DEST!" /E /XD python build dist .git .github logs __pycache__ /XF version.txt ZeroLive_Install.bat installer_gui.py build_installer.py ZeroLive_Installer.spec .gitignore .gitattributes .launch_args >nul
) else (
    echo       Downloading from GitHub...
    curl.exe -L -sS -o "%TEMP%\zerolive_install\src.zip" "!REPO!/archive/master.zip"
    if errorlevel 1 ( echo [ERROR] Source download failed. & pause & exit /b 1 )
    tar.exe -xf "%TEMP%\zerolive_install\src.zip" -C "%TEMP%\zerolive_install"
    robocopy "%TEMP%\zerolive_install\Zerolive-master" "!DEST!" /E /XD python build dist .git .github /XF version.txt ZeroLive_Install.bat installer_gui.py build_installer.py ZeroLive_Installer.spec .gitignore .gitattributes .launch_args >nul
)
if not exist "!DEST!\app.py" ( echo [ERROR] App files missing. & pause & exit /b 1 )

rem ---- 4. Dependencies --------------------------------------------------
echo [5/7] Installing dependencies...
if exist "!DEST!\requirements.txt" (
    "!PYEXE!" -m pip install -r "!DEST!\requirements.txt" --quiet
    if errorlevel 1 echo [WARN] Some dependencies may have failed.
)

rem ---- 5. Version -------------------------------------------------------
echo [6/7] Writing version...
"!PYEXE!" -c "import urllib.request,json;print(json.load(urllib.request.urlopen('!REPO_API!/commits/master',timeout=10))['sha'])" > "%TEMP%\zerolive_install\sha.txt" 2>nul
set /p LATEST_SHA=<"%TEMP%\zerolive_install\sha.txt"
if defined LATEST_SHA ( echo !LATEST_SHA!> "!DEST!\version.txt" ) else ( echo 1.0.0> "!DEST!\version.txt" )

rem ---- 6. Shortcuts + extras -------------------------------------------
echo [7/7] Creating shortcuts...
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\ZeroLive.lnk'); $s.TargetPath = '!DEST!\Zero_live.bat'; $s.WorkingDirectory = '!DEST!'; $s.Description = 'ZeroLive - Free Sports Streaming'; $s.Save()" >nul 2>&1
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\ZeroLive Uninstall.lnk'); $s.TargetPath = '!DEST!\uninstall.bat'; $s.WorkingDirectory = '!DEST!'; $s.Description = 'Remove ZeroLive'; $s.Save()" >nul 2>&1

net session >nul 2>&1 && (
    netsh advfirewall firewall add rule name=ZeroLive dir=in action=allow program="!DEST!\python\python.exe" profile=private enable=yes >nul 2>&1
    echo       Firewall rule added.
)

if not exist "!DEST!\default_theme.txt" echo dark> "!DEST!\default_theme.txt"
if not exist "!DEST!\readme.txt" (
    echo +==============================================+> "!DEST!\readme.txt"
    echo ^|    ZeroLive - Free Sports Streaming          ^|>> "!DEST!\readme.txt"
    echo +==============================================+>> "!DEST!\readme.txt"
    echo.>> "!DEST!\readme.txt"
    echo  *  Double-click 'ZeroLive' on desktop to start>> "!DEST!\readme.txt"
    echo  *  Opens at http://127.0.0.1:9090>> "!DEST!\readme.txt"
    echo.>> "!DEST!\readme.txt"
    echo  *  Double-click 'ZeroLive Uninstall' to remove>> "!DEST!\readme.txt"
)

rmdir /S /Q "%TEMP%\zerolive_install" >nul 2>&1

echo.
echo ============================================
echo   Installation complete!
echo ============================================
echo.

choice /c YN /m "Launch ZeroLive now?"
if errorlevel 2 exit /b

start "" /D "!DEST!" "!DEST!\Zero_live.bat"
exit /b
