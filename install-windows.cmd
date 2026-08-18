@echo off
setlocal EnableExtensions
rem Install copkg + coasm-windows next to MSVC tuc (build-win/lib).
set ROOT=%~dp0
rem Trim trailing spaces from TU_PREFIX (cmd "set X=path &&" leaves a space).
for /f "tokens=* delims= " %%A in ("%TU_PREFIX%") do set PREFIX=%%A
if "%PREFIX%"=="" set PREFIX=E:\Workspace\co\build-win

set COPKG=%PREFIX%\lib\copkg
set COASM=%PREFIX%\lib\coasm-windows
set COPEFF=%PREFIX%\lib\copeff
set COPEFF_SRC=%ROOT%..\co\linker\peff
if not exist "%COPEFF_SRC%\stub_entry.s" set COPEFF_SRC=E:\Workspace\co\linker\peff

echo [install-windows] prefix=%PREFIX%
if not exist "%COPKG%" mkdir "%COPKG%"
if not exist "%COASM%" mkdir "%COASM%"
if not exist "%COPEFF%" mkdir "%COPEFF%"

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
rem RFC-107 P1: WSA errno map in Tu (same runtime package → runtime_win_wsa_errno_neg).
copy /y "%ROOT%platform\windows\wsa_errno.tu" "%COPKG%\runtime\wsa_errno.tu" >nul
rem RFC-107 P1: fd / epoll maps, ctl/wait, AF rewrite, eventfd loopback fill.
copy /y "%ROOT%platform\windows\fd_table.tu" "%COPKG%\runtime\fd_table.tu" >nul
copy /y "%ROOT%platform\windows\epoll_soft.tu" "%COPKG%\runtime\epoll_soft.tu" >nul
copy /y "%ROOT%platform\windows\sock_flags.tu" "%COPKG%\runtime\sock_flags.tu" >nul
copy /y "%ROOT%platform\windows\pipe.tu" "%COPKG%\runtime\pipe.tu" >nul
rem Overlay Windows netio platform hooks (connect finish / accept prep).
copy /y "%ROOT%platform\windows\netio_platform.tu" "%COPKG%\netio\sys\platform.tu" >nul
if errorlevel 1 (
  echo [install-windows] ERROR: netio platform overlay failed
  exit /b 3
)
for %%F in ("%COPKG%\netio\sys\platform.tu") do echo [install-windows] platform overlay %%~zF bytes
rem Drop Darwin-only kqueue sources from the Windows package tree.
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
echo [install-windows] copkg + coasm-windows + copeff
endlocal
