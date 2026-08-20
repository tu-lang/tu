@echo off
chcp 65001 >nul
setlocal EnableExtensions
rem One-click Windows install: copkg + coasm + tu.exe into a prefix, then user PATH.
rem Default prefix: %LOCALAPPDATA%\tu  (override with TU_PREFIX, e.g. build-win for toolchain).
rem Requires: release\tu-windows (from `make dev_release` on Unix, or VS INSTALL / dev_release.ps1).
set ROOT=%~dp0
set DEVINSTALL=0
if not "%TU_PREFIX%"=="" set DEVINSTALL=1
for /f "tokens=* delims= " %%A in ("%TU_PREFIX%") do set PREFIX=%%A
if "%PREFIX%"=="" set PREFIX=%LOCALAPPDATA%\tu

set COPKG=%PREFIX%\lib\copkg
set COASM=%PREFIX%\lib\coasm-windows
set COPEFF=%PREFIX%\lib\copeff
set COPEFF_SRC=%ROOT%linker\peff

if not exist "%ROOT%release\tu-windows" (
  if "%DEVINSTALL%"=="0" (
    echo [install-windows] ERROR: missing "%ROOT%release\tu-windows"
    echo [install-windows] maintainers: from Linux/macOS run `make dev_release`; on Windows VS INSTALL or powershell -NoProfile -File "%ROOT%..\co\windows\dev_release.ps1"
    exit /b 4
  )
)

echo [install-windows] prefix=%PREFIX%
if not exist "%COPKG%" mkdir "%COPKG%"
if not exist "%COASM%" mkdir "%COASM%"
if not exist "%COPEFF%" mkdir "%COPEFF%"
if not exist "%PREFIX%\bin" mkdir "%PREFIX%\bin"

rem Mirror in place (avoid rmdir while tests hold handles under copkg).
rem robocopy exit 0-7 = success; mask with "|| rem" so cmd does not treat nonzero as fail.
robocopy "%ROOT%runtime" "%COPKG%\runtime" /MIR /NFL /NDL /NJH /NJS /nc /ns /np >nul
if errorlevel 8 echo [install-windows] robocopy runtime failed & exit /b 1
robocopy "%ROOT%library" "%COPKG%" /E /NFL /NDL /NJH /NJS /nc /ns /np >nul
if errorlevel 8 echo [install-windows] robocopy library failed & exit /b 1
robocopy "%ROOT%packages" "%COPKG%" /E /NFL /NDL /NJH /NJS /nc /ns /np >nul
if errorlevel 8 echo [install-windows] robocopy packages failed & exit /b 1

del /f /q "%COPKG%\runtime\linux.tu" 2>nul
del /f /q "%COPKG%\runtime\darwin.tu" 2>nul
copy /y "%ROOT%platform\windows\runtime_os.tu" "%COPKG%\runtime\windows.tu" >nul
copy /y "%ROOT%platform\windows\wsa_errno.tu" "%COPKG%\runtime\wsa_errno.tu" >nul
copy /y "%ROOT%platform\windows\fd_table.tu" "%COPKG%\runtime\fd_table.tu" >nul
copy /y "%ROOT%platform\windows\epoll_soft.tu" "%COPKG%\runtime\epoll_soft.tu" >nul
copy /y "%ROOT%platform\windows\sock_flags.tu" "%COPKG%\runtime\sock_flags.tu" >nul
copy /y "%ROOT%platform\windows\pipe.tu" "%COPKG%\runtime\pipe.tu" >nul
copy /y "%ROOT%platform\windows\netio_platform.tu" "%COPKG%\netio\sys\platform.tu" >nul
if errorlevel 1 (
  echo [install-windows] ERROR: netio platform overlay failed
  exit /b 3
)
for %%F in ("%COPKG%\netio\sys\platform.tu") do echo [install-windows] platform overlay %%~zF bytes
del /f /q "%COPKG%\netio\sys\kqueue.tu" 2>nul
del /f /q "%COPKG%\netio\sys\waker_kqueue.tu" 2>nul
copy /y "%ROOT%syscall\windows\*.s" "%COASM%\" >nul
copy /y "%COPEFF_SRC%\stub_entry.s" "%COPEFF%\" >nul 2>nul
copy /y "%COPEFF_SRC%\stub_runtime.s" "%COPEFF%\" >nul 2>nul
if not exist "%COPEFF%\stub_entry.s" copy /y "%COPEFF_SRC%\stub_*.s" "%COPEFF%\" >nul

if not exist "%COPKG%\asyncio\net\udp\socket.tu" (
  echo [install-windows] ERROR: asyncio missing after copy
  exit /b 2
)
if not exist "%COPKG%\std" (
  echo [install-windows] ERROR: std missing after copy
  exit /b 2
)

if exist "%ROOT%release\tu-windows" (
  copy /y "%ROOT%release\tu-windows" "%PREFIX%\bin\tu.exe" >nul
  if errorlevel 1 (
    echo [install-windows] ERROR: copy tu.exe failed
    exit /b 5
  )
  if exist "%PREFIX%\RelWithDebInfo" copy /y "%ROOT%release\tu-windows" "%PREFIX%\RelWithDebInfo\tu.exe" >nul
  echo [install-windows] tu.exe -^> "%PREFIX%\bin\tu.exe"
) else (
  echo [install-windows] skip tu.exe ^(no release/tu-windows yet^)
)

rem Persist user PATH only for the default %LOCALAPPDATA%\tu install (not TU_PREFIX/dev).
if "%DEVINSTALL%"=="0" (
  "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%ROOT%..\co\windows\install_user_path.ps1" -BinDir "%PREFIX%\bin"
  if errorlevel 1 echo [install-windows] warn: user PATH not updated
)
set "PATH=%PREFIX%\bin;%PATH%"

echo.
echo ============================================================
echo  Tu installed
echo ============================================================
echo   binary : %PREFIX%\bin\tu.exe
echo   stdlib : %PREFIX%\lib\copkg
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
echo   Same commands in cmd, PowerShell, and Git Bash.
echo   tu.exe compiles, assembles, and links by itself. No Visual Studio required.
echo ============================================================
echo.

if exist "%PREFIX%\bin\tu.exe" (
  echo [install-windows] verify:
  "%PREFIX%\bin\tu.exe" -v
  if errorlevel 1 (
    echo [install-windows] WARN: tu.exe -v failed
  )
)
endlocal
