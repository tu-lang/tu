@echo off
chcp 65001 >nul
setlocal EnableExtensions
rem One-click Windows install: tu.exe only (stdlib embedded in the binary).
rem Default prefix: %LOCALAPPDATA%\tu  (override with TU_PREFIX).
rem Requires: release\tu-windows (maintainers: `make dev_release` on Linux/macOS).
set ROOT=%~dp0
set DEVINSTALL=0
if not "%TU_PREFIX%"=="" set DEVINSTALL=1
for /f "tokens=* delims= " %%A in ("%TU_PREFIX%") do set PREFIX=%%A
if "%PREFIX%"=="" set PREFIX=%LOCALAPPDATA%\tu

if not exist "%ROOT%release\tu-windows" (
  echo [install-windows] ERROR: missing "%ROOT%release\tu-windows"
  echo [install-windows] maintainers: from Linux/macOS run `make dev_release`
  exit /b 4
)

echo [install-windows] prefix=%PREFIX% (bin only)
if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

copy /y "%ROOT%release\tu-windows" "%PREFIX%\bin\tu.exe" >nul
if errorlevel 1 (
  echo [install-windows] ERROR: copy tu.exe failed
  exit /b 5
)
echo [install-windows] tu.exe -^> "%PREFIX%\bin\tu.exe"

rem Persist user PATH only for the default %LOCALAPPDATA%\tu install (not TU_PREFIX/dev).
if "%DEVINSTALL%"=="0" (
  "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\windows\install_user_path.ps1" -BinDir "%PREFIX%\bin"
  if errorlevel 1 echo [install-windows] warn: user PATH not updated
)
set "PATH=%PREFIX%\bin;%PATH%"

echo.
echo ============================================================
echo  Tu installed (binary only)
echo ============================================================
echo   binary : %PREFIX%\bin\tu.exe
echo   stdlib : embedded in tu.exe
echo.
if "%DEVINSTALL%"=="0" (
  echo   PATH    : user PATH now includes %PREFIX%\bin
  echo             Open a NEW terminal. Already-open Cursor/IDE terminals keep the old PATH.
) else (
  echo   PATH    : TU_PREFIX dev install; user PATH was not changed.
)
echo.
echo   Next:
echo     tu -v
echo     tu run hello.tu
echo.
echo ============================================================
echo.

echo [install-windows] verify:
"%PREFIX%\bin\tu.exe" -v
if errorlevel 1 (
  echo [install-windows] WARN: tu.exe -v failed
)
endlocal
