@echo off
setlocal EnableExtensions
rem Install copkg + coasm-windows next to MSVC tuc (build-win/lib).
set ROOT=%~dp0
set PREFIX=%TU_PREFIX%
if "%PREFIX%"=="" set PREFIX=E:\Workspace\co\build-win

set COPKG=%PREFIX%\lib\copkg
set COASM=%PREFIX%\lib\coasm-windows
set COPEFF=%PREFIX%\lib\copeff

echo [install-windows] prefix=%PREFIX%
if exist "%COPKG%" rmdir /s /q "%COPKG%"
mkdir "%COPKG%"
mkdir "%COASM%"
mkdir "%COPEFF%"

xcopy /e /i /y "%ROOT%runtime" "%COPKG%\runtime" >nul
xcopy /e /i /y "%ROOT%library\*" "%COPKG%\" >nul
xcopy /e /i /y "%ROOT%packages\*" "%COPKG%\" >nul
del /f /q "%COPKG%\runtime\linux.tu" 2>nul
del /f /q "%COPKG%\runtime\darwin.tu" 2>nul
copy /y "%ROOT%platform\windows\runtime_os.tu" "%COPKG%\runtime\windows.tu" >nul
rem Overlay Windows netio platform hooks (connect finish / accept prep).
copy /y "%ROOT%platform\windows\netio_platform.tu" "%COPKG%\netio\sys\platform.tu" >nul
rem Drop Darwin-only kqueue sources from the Windows package tree.
del /f /q "%COPKG%\netio\sys\kqueue.tu" 2>nul
del /f /q "%COPKG%\netio\sys\waker_kqueue.tu" 2>nul
copy /y "%ROOT%syscall\windows\*.s" "%COASM%\" >nul
copy /y "%ROOT%\..\co\linker\peff\stub_entry.s" "%COPEFF%\" >nul 2>nul
copy /y "%ROOT%\..\co\linker\peff\stub_runtime.s" "%COPEFF%\" >nul 2>nul
if not exist "%COPEFF%\stub_entry.s" copy /y "E:\Workspace\co\linker\peff\stub_*.s" "%COPEFF%\" >nul

echo [install-windows] copkg + coasm-windows + copeff
endlocal
